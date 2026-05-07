module OpenAPITemplate

using PkgTemplates: PkgTemplates, Codecov, CompatHelper, Formatter, Git,
    GitHubActions, License, Plugin, ProjectFile, Readme, SrcDir, TagBot,
    Template, pkg_name

const TEMPLATES_DIR = joinpath(@__DIR__, "templates")
const API_PAGES_SRC = joinpath(@__DIR__, "api_pages.jl")

# Defines `emit_api_pages(spec_path, dst_dir)` in this module's namespace.
# The same file is `cp`'d into user packages as `gen/emit_api_pages.jl` so
# the function can also be re-run from `gen/regenerate.jl` whenever the
# spec changes.
include("api_pages.jl")

include("plugins/OpenAPISpec.jl")
include("plugins/ClientLayer.jl")
include("plugins/Reliability.jl")
include("plugins/BrokenRecordTests.jl")
include("plugins/VitepressDocs.jl")
include("plugins/PreCommitChecks.jl")

export APIWrapper,
    OpenAPISpec, ClientLayer, Reliability, BrokenRecordTests, VitepressDocs,
    PreCommitChecks

"""
    APIWrapper(; spec_url=nothing,
                 auth_modes=[:bearer],
                 retry=true,
                 rate_limit=true,
                 deploy_docs=true) -> Vector{Plugin}

Return the composed plugin list for scaffolding a Julia REST/JSON API wrapper
package. Pass directly to `PkgTemplates.Template(; plugins=APIWrapper(...))`.

# Example

```julia
t = Template(;
    user = "your-username",
    dir  = pwd(),                      # ← see warning below
    plugins = APIWrapper(; spec_url = "https://example.com/openapi.json"),
)
t("MyWrapper")
```

!!! warning "Output directory"
    `Template` does not use your current working directory. PkgTemplates
    defaults `dir` to `~/.julia/dev`, so without an explicit `dir = ...` your
    package will land in `~/.julia/dev/<PackageName>` regardless of where
    you ran Julia. Pass `dir = pwd()` (or any absolute path) to put it
    elsewhere. The default exists so the result is immediately usable via
    `]dev <name>`.

The plugin list wires `OpenAPISpec`, `ClientLayer`, `Reliability`,
`BrokenRecordTests`, `VitepressDocs`, and `PreCommitChecks` on top of the
standard PkgTemplates plugins (`ProjectFile`, `SrcDir`, `Readme`, `License`,
`Git`, `Formatter`, `GitHubActions`, `Codecov`, `CompatHelper`, `TagBot`).
"""
function APIWrapper(;
        spec_url::Union{Nothing, AbstractString} = nothing,
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
        PreCommitChecks(),
    ]
end

end # module
