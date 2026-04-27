module OpenAPITemplate

using PkgTemplates
using PkgTemplates: Plugin, Template, pkg_name

include("plugins/OpenAPISpec.jl")
include("plugins/ClientLayer.jl")
include("plugins/Reliability.jl")
include("plugins/BrokenRecordTests.jl")
include("plugins/VitepressDocs.jl")

export APIWrapper,
    OpenAPISpec, ClientLayer, Reliability, BrokenRecordTests, VitepressDocs

const TEMPLATES_DIR = joinpath(@__DIR__, "templates")

"""
    APIWrapper(; spec_url=nothing,
                 auth_modes=[:bearer],
                 retry=true,
                 rate_limit=true,
                 deploy_docs=true) -> Vector{Plugin}

Return the composed plugin list for scaffolding a Julia REST/JSON API wrapper
package. Pass directly to `PkgTemplates.Template(; plugins=APIWrapper(...))`.

Phase 1 wires the five sub-plugins (mostly stubs) on top of the standard
PkgTemplates plugins. OpenAPI codegen, middleware, reliability, and docs
integration are filled in by later phases.
"""
function APIWrapper(;
    spec_url::Union{Nothing,AbstractString} = nothing,
    auth_modes::Vector{Symbol} = [:bearer],
    retry::Bool = true,
    rate_limit::Bool = true,
    deploy_docs::Bool = true,
)
    return Any[
        # Disable the default `Tests` plugin — `BrokenRecordTests` owns the
        # generated package's test scaffolding.
        !PkgTemplates.Tests,
        ProjectFile(),
        SrcDir(),
        Readme(),
        License(),
        Git(),
        Formatter(),
        GitHubActions(),
        Codecov(),
        CompatHelper(),
        TagBot(),
        OpenAPISpec(; spec_url),
        ClientLayer(; auth_modes),
        Reliability(; retry, rate_limit),
        BrokenRecordTests(),
        VitepressDocs(; deploy = deploy_docs),
    ]
end

end # module
