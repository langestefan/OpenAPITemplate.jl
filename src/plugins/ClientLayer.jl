using Pkg: Pkg, PackageSpec
using PkgTemplates: with_project
using TOML: TOML

const HTTP_UUID = "cd3eb016-35fb-5094-929b-558a96fad6f3"
const JSON_UUID = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
const OPENAPI_UUID = "d5e62ea6-ddf3-4d43-8e4c-ad5e6c8bfd7d"
const BASE64_UUID = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
const TOML_UUID = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
const LOGGING_UUID = "56ddb016-857b-54e1-b83d-db4d58db5568"

const RUNTIME_DEPS = [
    (name = "Base64", uuid = BASE64_UUID, compat = "1"),
    (name = "HTTP", uuid = HTTP_UUID, compat = "1"),
    (name = "JSON", uuid = JSON_UUID, compat = "1"),
    (name = "Logging", uuid = LOGGING_UUID, compat = "1"),
    (name = "OpenAPI", uuid = OPENAPI_UUID, compat = "0.2"),
    (name = "TOML", uuid = TOML_UUID, compat = "1"),
]

"""
    ClientLayer(; auth_modes=[:bearer])

Scaffolds the hand-written ergonomic client overlay (`src/<PKG>/client/`) and
adds the runtime dependencies (HTTP, JSON, OpenAPI) to the generated package's
`Project.toml`.

Phase 1 emits a bare `Client` struct and a module file that includes it. Auth
strategies, middleware, and pagination land in Phase 3.
"""
Base.@kwdef struct ClientLayer <: Plugin
    auth_modes::Vector{Symbol} = [:bearer]
end

# Run after stock plugins (priority 1000), before OpenAPISpec (100), before Git (5).
PkgTemplates.priority(::ClientLayer, ::typeof(PkgTemplates.posthook)) = 200

function PkgTemplates.posthook(p::ClientLayer, ::Template, pkg_dir::AbstractString)
    pkg = pkg_name(pkg_dir)
    _write_client_file(pkg_dir, pkg)
    _rewrite_module_file(pkg_dir, pkg)
    _add_runtime_deps(pkg_dir)
    return nothing
end

function _write_client_file(pkg_dir::AbstractString, pkg::AbstractString)
    client_dir = joinpath(pkg_dir, "src", "client")
    mkpath(client_dir)
    for fname in (
            "auth.jl", "errors.jl", "logging.jl", "retry.jl", "rate_limit.jl",
            "timeout.jl", "middleware.jl", "Client.jl", "pagination.jl", "show.jl",
        )
        src = joinpath(TEMPLATES_DIR, "client", fname * ".tpl")
        write(joinpath(client_dir, fname), _render(read(src, String), pkg))
    end
    return
end

function _rewrite_module_file(pkg_dir::AbstractString, pkg::AbstractString)
    src = joinpath(TEMPLATES_DIR, "module.jl.tpl")
    dst = joinpath(pkg_dir, "src", "$(pkg).jl")
    return write(dst, _render(read(src, String), pkg))
end

function _render(text::AbstractString, pkg::AbstractString)
    text = replace(text, "{{PKG_UPPER}}" => uppercase(pkg))
    text = replace(text, "{{PKG_LOWER}}" => lowercase(pkg))
    return replace(text, "{{PKG}}" => pkg)
end

function _add_runtime_deps(pkg_dir::AbstractString)
    specs = [PackageSpec(; name = d.name, uuid = d.uuid) for d in RUNTIME_DEPS]
    with_project(pkg_dir) do
        Pkg.add(specs)
    end
    return _set_compat(pkg_dir)
end

function _set_compat(pkg_dir::AbstractString)
    path = joinpath(pkg_dir, "Project.toml")
    toml = TOML.parsefile(path)
    compat = get!(toml, "compat", Dict{String, Any}())
    for d in RUNTIME_DEPS
        compat[d.name] = d.compat
    end
    return open(path, "w") do io
        TOML.print(io, toml; sorted = true)
    end
end
