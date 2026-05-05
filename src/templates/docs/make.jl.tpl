using Documenter, DocumenterVitepress
using {{PKG}}

# Bundle the committed OpenAPI spec into Vitepress's `public/` so the
# vitepress-openapi components can fetch it from the deployed site.
const SPEC_SRC = joinpath(pkgdir({{PKG}}), "spec", "openapi.json")
if isfile(SPEC_SRC)
    SPEC_DST = joinpath(@__DIR__, "src", "public", "openapi.json")
    mkpath(dirname(SPEC_DST))
    cp(SPEC_SRC, SPEC_DST; force = true)
end

const PAGES = Any[
    "Home" => "index.md",
    "Getting Started" => "getting_started.md",
    "Julia API Reference" => "julia_reference.md",
]
isfile(joinpath(@__DIR__, "src", "api", "index.md")) &&
    push!(PAGES, "REST API Reference" => "api/index.md")

makedocs(;
    modules = [{{PKG}}],
    sitename = "{{PKG}}.jl",
    authors = "{{USER}}",
    format = MarkdownVitepress(;
        repo = "github.com/{{USER}}/{{PKG}}.jl",
        devbranch = "main",
        devurl = "dev",
    ),
    pages = PAGES,
    warnonly = true,
)

deploydocs(;
    repo = "github.com/{{USER}}/{{PKG}}.jl",
    target = "build",
    branch = "gh-pages",
    devbranch = "main",
    push_preview = true,
)
