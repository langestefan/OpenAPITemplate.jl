using Downloads: download
using Dates: now
using TOML
using Pkg
using PkgTemplates: with_project

const GENERATOR_VERSION = "7.10.0"
const NPM_WRAPPER_VERSION = "2.21.4"

# Direct deps the generated module pulls in (transitive deps of OpenAPI but
# the generated `using ...` line needs them declared explicitly).
const CODEGEN_DEPS = [
    (name = "Dates", uuid = "ade2ca70-3891-5945-98fb-dc099432e06a", compat = nothing),
    (name = "TimeZones", uuid = "f269a46b-ccf7-5d73-abea-4c690281aa53", compat = "1"),
]

"""
    OpenAPISpec(; spec_url=nothing,
                  gen_dir="src/api",
                  generator_version=$(repr(GENERATOR_VERSION)))

Drives the OpenAPI Generator `julia-client` at scaffold time. When `spec_url`
is set:

  - Saves the spec to `spec/openapi.json`.
  - Writes `gen/openapi-config.json` and `gen/regenerate.jl`.
  - Runs `openapi-generator-cli` once via `npx`, populating `src/api/`.
  - Re-writes `src/<PKG>.jl` to include and re-export the generated module.
  - Adds `src/api/** linguist-generated=true` to `.gitattributes`.
  - Records spec URL, generator version, and timestamp in `scaffold-info.toml`.

`spec_url` may be an `http(s)://` URL or a local path. With `spec_url=nothing`,
this plugin is a no-op (the rest of Phase 1 still produces a working package).
"""
Base.@kwdef struct OpenAPISpec <: Plugin
    spec_url::Union{Nothing,String} = nothing
    gen_dir::String = "src/api"
    generator_version::String = GENERATOR_VERSION
end

# Higher priority runs first. ClientLayer writes the bare module at 200; this
# rewrites it at 100 (still ahead of Git's posthook at 5).
PkgTemplates.priority(::OpenAPISpec, ::typeof(PkgTemplates.posthook)) = 100

function PkgTemplates.posthook(p::OpenAPISpec, ::Template, pkg_dir::AbstractString)
    p.spec_url === nothing && return nothing

    Sys.which("java") === nothing && error(
        "OpenAPISpec: `java` not found on PATH. Install Java 11+ " *
        "(https://adoptium.net/) or scaffold without `spec_url` to skip codegen.",
    )

    pkg = pkg_name(pkg_dir)
    api_pkg = pkg * "API"

    spec_path = joinpath(pkg_dir, "spec", "openapi.json")
    _save_spec(p.spec_url, spec_path)

    _write_gen_files(pkg_dir, api_pkg, p.spec_url, p.generator_version)
    _run_codegen(pkg_dir, api_pkg, spec_path, p.generator_version)
    _add_codegen_deps(pkg_dir)
    _rewrite_module_with_api(pkg_dir, pkg, api_pkg)
    _add_gitattributes(pkg_dir)
    _write_scaffold_info(pkg_dir, p.spec_url, p.generator_version)
    return nothing
end

function _add_codegen_deps(pkg_dir::AbstractString)
    specs = [PackageSpec(; name = d.name, uuid = d.uuid) for d in CODEGEN_DEPS]
    with_project(pkg_dir) do
        Pkg.add(specs)
    end
    path = joinpath(pkg_dir, "Project.toml")
    toml = TOML.parsefile(path)
    compat = get!(toml, "compat", Dict{String,Any}())
    for d in CODEGEN_DEPS
        d.compat === nothing && continue
        compat[d.name] = d.compat
    end
    open(path, "w") do io
        TOML.print(io, toml; sorted = true)
    end
end

# ---------------------------------------------------------------------------
# Helpers

function _save_spec(spec_url::AbstractString, dst::AbstractString)
    mkpath(dirname(dst))
    if startswith(spec_url, r"^https?://"i)
        download(spec_url, dst)
    elseif isfile(spec_url)
        cp(spec_url, dst; force = true)
    else
        error("OpenAPISpec: spec_url is neither an HTTP URL nor an existing file: $spec_url")
    end
end

function _write_gen_files(
    pkg_dir::AbstractString,
    api_pkg::AbstractString,
    spec_url::AbstractString,
    generator_version::AbstractString,
)
    gen_dir = joinpath(pkg_dir, "gen")
    mkpath(gen_dir)

    config_src = joinpath(OpenAPITemplate.TEMPLATES_DIR, "gen", "openapi-config.json.tpl")
    config_dst = joinpath(gen_dir, "openapi-config.json")
    write(config_dst, _render_kv(read(config_src, String), Dict(
        "API_PKG" => api_pkg,
    )))

    regen_src = joinpath(OpenAPITemplate.TEMPLATES_DIR, "gen", "regenerate.jl.tpl")
    regen_dst = joinpath(gen_dir, "regenerate.jl")
    write(regen_dst, _render_kv(read(regen_src, String), Dict(
        "API_PKG" => api_pkg,
        "SPEC_URL" => spec_url,
        "GENERATOR_VERSION" => generator_version,
        "NPM_WRAPPER_VERSION" => NPM_WRAPPER_VERSION,
    )))
end

function _run_codegen(
    pkg_dir::AbstractString,
    api_pkg::AbstractString,
    spec_path::AbstractString,
    generator_version::AbstractString,
)
    api_target = joinpath(pkg_dir, "src", "api")
    mktempdir() do tmp
        out_dir = joinpath(tmp, "out")
        cmd = Cmd(`npx --yes @openapitools/openapi-generator-cli@$(NPM_WRAPPER_VERSION) generate
                   -i $spec_path
                   -g julia-client
                   -o $out_dir
                   --additional-properties=packageName=$(api_pkg),exportModels=true,exportOperations=true`;
                  dir = tmp)
        env = copy(ENV)
        env["OPENAPI_GENERATOR_VERSION"] = generator_version
        run(setenv(cmd, env))

        # Replace any prior contents.
        isdir(api_target) && rm(api_target; recursive = true)
        mkpath(api_target)
        for entry in readdir(joinpath(out_dir, "src"); join = false)
            cp(joinpath(out_dir, "src", entry), joinpath(api_target, entry))
        end
    end
end

function _rewrite_module_with_api(
    pkg_dir::AbstractString,
    pkg::AbstractString,
    api_pkg::AbstractString,
)
    src = joinpath(OpenAPITemplate.TEMPLATES_DIR, "module-with-api.jl.tpl")
    dst = joinpath(pkg_dir, "src", "$(pkg).jl")
    write(dst, _render_kv(read(src, String), Dict(
        "PKG" => pkg,
        "API_PKG" => api_pkg,
    )))
end

function _add_gitattributes(pkg_dir::AbstractString)
    path = joinpath(pkg_dir, ".gitattributes")
    line = "src/api/** linguist-generated=true\n"
    if isfile(path)
        contents = read(path, String)
        occursin(line, contents) && return nothing
        open(path, "a") do io
            endswith(contents, "\n") || write(io, "\n")
            write(io, line)
        end
    else
        write(path, line)
    end
end

function _write_scaffold_info(
    pkg_dir::AbstractString,
    spec_url::AbstractString,
    generator_version::AbstractString,
)
    info = Dict{String,Any}(
        "spec_path" => "spec/openapi.json",
        "spec_url" => spec_url,
        "generator_version" => generator_version,
        "generated_at" => string(now()),
    )
    open(joinpath(pkg_dir, "scaffold-info.toml"), "w") do io
        TOML.print(io, info; sorted = true)
    end
end

function _render_kv(text::AbstractString, vars::Dict{<:AbstractString,<:AbstractString})
    for (k, v) in vars
        text = replace(text, "{{$k}}" => v)
    end
    return text
end
