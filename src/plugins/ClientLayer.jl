using Pkg
using PkgTemplates: with_project
using TOML

const HTTP_UUID = "cd3eb016-35fb-5094-929b-558a96fad6f3"
const JSON_UUID = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
const OPENAPI_UUID = "d5e62ea6-ddf3-4d43-8e4c-ad5e6c8bfd7d"

const RUNTIME_DEPS = [
    (name = "HTTP", uuid = HTTP_UUID, compat = "1"),
    (name = "JSON", uuid = JSON_UUID, compat = "1"),
    (name = "OpenAPI", uuid = OPENAPI_UUID, compat = "0.2"),
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

# Run after stock plugins (priority 1000) but before Git (priority 5).
PkgTemplates.priority(::ClientLayer, ::typeof(PkgTemplates.posthook)) = 100

function PkgTemplates.posthook(p::ClientLayer, ::Template, pkg_dir::AbstractString)
    pkg = pkg_name(pkg_dir)
    _write_client_file(pkg_dir, pkg)
    _rewrite_module_file(pkg_dir, pkg)
    _add_runtime_deps(pkg_dir)
    return nothing
end

function _write_client_file(pkg_dir::AbstractString, pkg::AbstractString)
    src = joinpath(OpenAPITemplate.TEMPLATES_DIR, "client", "Client.jl.tpl")
    dst = joinpath(pkg_dir, "src", "client", "Client.jl")
    mkpath(dirname(dst))
    write(dst, _render(read(src, String), pkg))
end

function _rewrite_module_file(pkg_dir::AbstractString, pkg::AbstractString)
    src = joinpath(OpenAPITemplate.TEMPLATES_DIR, "module.jl.tpl")
    dst = joinpath(pkg_dir, "src", "$(pkg).jl")
    write(dst, _render(read(src, String), pkg))
end

_render(text::AbstractString, pkg::AbstractString) = replace(text, "{{PKG}}" => pkg)

function _add_runtime_deps(pkg_dir::AbstractString)
    specs = [PackageSpec(; name = d.name, uuid = d.uuid) for d in RUNTIME_DEPS]
    with_project(pkg_dir) do
        Pkg.add(specs)
    end
    _set_compat(pkg_dir)
end

function _set_compat(pkg_dir::AbstractString)
    path = joinpath(pkg_dir, "Project.toml")
    toml = TOML.parsefile(path)
    compat = get!(toml, "compat", Dict{String,Any}())
    for d in RUNTIME_DEPS
        compat[d.name] = d.compat
    end
    open(path, "w") do io
        TOML.print(io, toml; sorted = true)
    end
end
