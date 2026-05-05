using Test
using OpenAPITemplate
using PkgTemplates

@testset "VitepressDocs (no spec)" begin
    mktempdir() do dir
        t = Template(;
            user = "testuser",
            dir = dir,
            plugins = APIWrapper(),
            interactive = false,
        )
        t("ScratchDocs")
        pkg_dir = joinpath(dir, "ScratchDocs")
        docs_dir = joinpath(pkg_dir, "docs")

        @test isfile(joinpath(docs_dir, "Project.toml"))
        @test isfile(joinpath(docs_dir, "package.json"))
        @test isfile(joinpath(docs_dir, "make.jl"))
        @test isfile(joinpath(docs_dir, "src", "index.md"))
        @test isfile(joinpath(docs_dir, "src", "getting_started.md"))
        @test isfile(joinpath(docs_dir, "src", "julia_reference.md"))
        @test isfile(joinpath(pkg_dir, ".github", "workflows", "Documentation.yml"))

        # No spec → no api/ pages and no .vitepress/ theme.
        @test !isdir(joinpath(docs_dir, "src", "api"))
        @test !isdir(joinpath(docs_dir, ".vitepress"))

        # Substitution sanity.
        proj = read(joinpath(docs_dir, "Project.toml"), String)
        @test occursin("ScratchDocs =", proj)
        index = read(joinpath(docs_dir, "src", "index.md"), String)
        @test occursin("ScratchDocs.jl", index)
        @test occursin("github.com/testuser/ScratchDocs.jl", index)

        make = read(joinpath(docs_dir, "make.jl"), String)
        @test occursin("using ScratchDocs", make)
        @test occursin("repo = \"github.com/testuser/ScratchDocs.jl\"", make)
    end
end

@testset "VitepressDocs respects deploy=false" begin
    mktempdir() do dir
        t = Template(;
            user = "testuser",
            dir = dir,
            plugins = APIWrapper(; deploy_docs = false),
            interactive = false,
        )
        t("NoDeploy")
        pkg_dir = joinpath(dir, "NoDeploy")
        @test !isfile(joinpath(pkg_dir, ".github", "workflows", "Documentation.yml"))
        @test isfile(joinpath(pkg_dir, "docs", "make.jl"))
    end
end
