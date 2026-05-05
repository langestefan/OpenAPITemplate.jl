using OpenAPITemplate
using Documenter
using DocumenterVitepress

DocMeta.setdocmeta!(
    OpenAPITemplate,
    :DocTestSetup,
    :(using OpenAPITemplate);
    recursive = true,
)

makedocs(;
    modules = [OpenAPITemplate],
    authors = "Stefan de Lange <langestefan@msn.com>",
    sitename = "OpenAPITemplate.jl",
    format = DocumenterVitepress.MarkdownVitepress(;
        repo = "github.com/langestefan/OpenAPITemplate.jl",
        devbranch = "main",
        devurl = "dev",
        build_vitepress = true,
    ),
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Quick Start" => "quickstart.md",
            "Architecture" => "architecture.md",
            "Plugins" => "plugins.md",
            "Spec Conversion" => "spec-conversion.md",
        ],
        "Public API" => "api.md",
    ],
    warnonly = [:missing_docs],
)

DocumenterVitepress.deploydocs(;
    repo = "github.com/langestefan/OpenAPITemplate.jl",
    devbranch = "main",
    push_preview = true,
)
