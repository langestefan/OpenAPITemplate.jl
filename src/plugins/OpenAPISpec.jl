using Downloads: download
using Dates: now
using TOML: TOML
using Pkg: Pkg, PackageSpec
using PkgTemplates: with_project

const GENERATOR_VERSION = "7.10.0"
const NPM_WRAPPER_VERSION = "2.21.4"
const SWAGGER2OPENAPI_VERSION = "7.0.8"

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
  - **If the spec is Swagger 2.0**, runs `npx swagger2openapi` to convert it
    to OpenAPI 3.0 in place; the original is preserved as
    `spec/openapi.v2-original.json`. (The `julia-client` codegen handles both
    formats, but `vitepress-openapi` — used by the docs browser — only
    parses OAS 3+.)
  - Writes `gen/openapi-config.json` and `gen/regenerate.jl`.
  - Runs `openapi-generator-cli` once via `npx`, populating `src/api/`.
  - Re-writes `src/<PKG>.jl` to include and re-export the generated module.
  - Adds `src/api/** linguist-generated=true` to `.gitattributes`.
  - Records spec URL, generator version, and timestamp in `scaffold-info.toml`.

`spec_url` may be an `http(s)://` URL or a local path. With `spec_url=nothing`,
this plugin is a no-op and the rest of the template still produces a
working hand-written-only package.
"""
Base.@kwdef struct OpenAPISpec <: Plugin
    spec_url::Union{Nothing, String} = nothing
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
    _normalize_to_oas3!(spec_path)

    _write_gen_files(pkg_dir, api_pkg, p.spec_url, p.generator_version)
    _run_codegen(pkg_dir, api_pkg, spec_path, p.generator_version)
    _add_codegen_deps(pkg_dir)
    _rewrite_module_with_api(pkg_dir, pkg, api_pkg)
    _add_gitattributes(pkg_dir)
    _write_scaffold_info(pkg_dir, p.spec_url, p.generator_version)
    _write_drift_check_workflow(pkg_dir)
    return nothing
end

function _write_drift_check_workflow(pkg_dir::AbstractString)
    src = joinpath(TEMPLATES_DIR, "gen", "regen-check.yml.tpl")
    dst = joinpath(pkg_dir, ".github", "workflows", "regen-check.yml")
    mkpath(dirname(dst))
    return cp(src, dst; force = true)
end

function _add_codegen_deps(pkg_dir::AbstractString)
    specs = [PackageSpec(; name = d.name, uuid = d.uuid) for d in CODEGEN_DEPS]
    with_project(pkg_dir) do
        Pkg.add(specs)
    end
    path = joinpath(pkg_dir, "Project.toml")
    toml = TOML.parsefile(path)
    compat = get!(toml, "compat", Dict{String, Any}())
    for d in CODEGEN_DEPS
        d.compat === nothing && continue
        compat[d.name] = d.compat
    end
    return open(path, "w") do io
        TOML.print(io, toml; sorted = true)
    end
end

# ---------------------------------------------------------------------------
# Helpers

function _save_spec(spec_url::AbstractString, dst::AbstractString)
    mkpath(dirname(dst))
    return if startswith(spec_url, r"^https?://"i)
        download(spec_url, dst)
    elseif isfile(spec_url)
        cp(spec_url, dst; force = true)
    else
        error("OpenAPISpec: spec_url is neither an HTTP URL nor an existing file: $spec_url")
    end
end

# Detects Swagger 2.0 by string-scanning the spec and converts it to OpenAPI
# 3.0 in place via `npx swagger2openapi`. The original v2 file is preserved
# alongside the canonical 3.0 output. Conversion is needed because
# `vitepress-openapi` (the docs browser) only parses OAS 3+. The
# `julia-client` codegen handles both, so this is purely for the docs layer.
function _normalize_to_oas3!(spec_path::AbstractString)
    head = read(spec_path, String)
    # Sample the first 1KB for the version key — enough for any well-formed
    # spec since `swagger`/`openapi` is a top-level field.
    sample = head[1:min(1024, lastindex(head))]
    is_v2 = occursin(r"\"swagger\"\s*:\s*\"2\.", sample) &&
        !occursin(r"\"openapi\"\s*:\s*\"3", sample)
    is_v2 || return nothing

    Sys.which("npx") === nothing && error(
        "OpenAPISpec: spec is Swagger 2.0; converting to OpenAPI 3.0 needs " *
            "`npx` (Node 18+). Install Node or feed an OAS 3.x spec.",
    )

    backup = replace(spec_path, r"\.json$" => ".v2-original.json")
    cp(spec_path, backup; force = true)
    cmd = `npx --yes swagger2openapi@$(SWAGGER2OPENAPI_VERSION) $spec_path -o $spec_path`
    run(cmd)
    @info "OpenAPISpec: converted Swagger 2.0 → OpenAPI 3.0 (original saved as " *
        "`spec/$(basename(backup))`). The v3 form is required for the " *
        "Vitepress REST API browser."
    return nothing
end

function _write_gen_files(
        pkg_dir::AbstractString,
        api_pkg::AbstractString,
        spec_url::AbstractString,
        generator_version::AbstractString,
    )
    gen_dir = joinpath(pkg_dir, "gen")
    mkpath(gen_dir)

    config_src = joinpath(TEMPLATES_DIR, "gen", "openapi-config.json.tpl")
    config_dst = joinpath(gen_dir, "openapi-config.json")
    write(
        config_dst, _render_kv(
            read(config_src, String), Dict(
                "API_PKG" => api_pkg,
            )
        )
    )

    regen_src = joinpath(TEMPLATES_DIR, "gen", "regenerate.jl.tpl")
    regen_dst = joinpath(gen_dir, "regenerate.jl")
    return write(
        regen_dst, _render_kv(
            read(regen_src, String), Dict(
                "API_PKG" => api_pkg,
                "SPEC_URL" => spec_url,
                "GENERATOR_VERSION" => generator_version,
                "NPM_WRAPPER_VERSION" => NPM_WRAPPER_VERSION,
            )
        )
    )
end

function _run_codegen(
        pkg_dir::AbstractString,
        api_pkg::AbstractString,
        spec_path::AbstractString,
        generator_version::AbstractString,
    )
    api_target = joinpath(pkg_dir, "src", "api")
    return mktempdir() do tmp
        out_dir = joinpath(tmp, "out")
        cmd = Cmd(
            `npx --yes @openapitools/openapi-generator-cli@$(NPM_WRAPPER_VERSION) generate
                   -i $spec_path
                   -g julia-client
                   -o $out_dir
                   --additional-properties=packageName=$(api_pkg),exportModels=true,exportOperations=true`;
            dir = tmp
        )
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
    src = joinpath(TEMPLATES_DIR, "module-with-api.jl.tpl")
    dst = joinpath(pkg_dir, "src", "$(pkg).jl")
    return write(
        dst, _render_kv(
            read(src, String), Dict(
                "PKG" => pkg,
                "API_PKG" => api_pkg,
            )
        )
    )
end

function _add_gitattributes(pkg_dir::AbstractString)
    path = joinpath(pkg_dir, ".gitattributes")
    line = "src/api/** linguist-generated=true\n"
    return if isfile(path)
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
    info = Dict{String, Any}(
        "spec_path" => "spec/openapi.json",
        "spec_url" => spec_url,
        "generator_version" => generator_version,
        "generated_at" => string(now()),
    )
    return open(joinpath(pkg_dir, "scaffold-info.toml"), "w") do io
        TOML.print(io, info; sorted = true)
    end
end

function _render_kv(text::AbstractString, vars::Dict{<:AbstractString, <:AbstractString})
    for (k, v) in vars
        text = replace(text, "{{$k}}" => v)
    end
    return text
end
