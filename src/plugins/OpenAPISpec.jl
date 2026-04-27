"""
    OpenAPISpec(; spec_url=nothing, gen_dir="src/api")

Phase-1 stub for the OpenAPI codegen integration. When `spec_url` is set, this
will eventually drive `openapi-generator-cli` to produce `src/api/`. For now it
only records intent in a log message.
"""
Base.@kwdef struct OpenAPISpec <: Plugin
    spec_url::Union{Nothing,String} = nothing
    gen_dir::String = "src/api"
end

PkgTemplates.priority(::OpenAPISpec, ::typeof(PkgTemplates.posthook)) = 200

function PkgTemplates.posthook(p::OpenAPISpec, ::Template, pkg_dir::AbstractString)
    if p.spec_url !== nothing
        @info "OpenAPISpec: spec_url set; codegen will run in Phase 2." spec_url = p.spec_url pkg = pkg_name(pkg_dir)
    end
    return nothing
end
