using Test
using OpenAPITemplate
using PkgTemplates

@testset "OpenAPITemplate Phase 1" begin
    mktempdir() do dir
        t = Template(;
            user = "testuser",
            dir = dir,
            plugins = APIWrapper(),
            interactive = false,
        )
        t("ScratchAPI")

        pkg_dir = joinpath(dir, "ScratchAPI")
        @test isdir(pkg_dir)
        @test isfile(joinpath(pkg_dir, "Project.toml"))
        @test isfile(joinpath(pkg_dir, "src", "ScratchAPI.jl"))
        @test isfile(joinpath(pkg_dir, "src", "client", "Client.jl"))
        @test isfile(joinpath(pkg_dir, "test", "runtests.jl"))

        # Module file should include the client overlay.
        module_src = read(joinpath(pkg_dir, "src", "ScratchAPI.jl"), String)
        @test occursin("include(\"client/Client.jl\")", module_src)
        @test occursin("using HTTP, JSON, OpenAPI", module_src)

        # Project.toml should pick up the runtime deps + compat bounds.
        proj = read(joinpath(pkg_dir, "Project.toml"), String)
        @test occursin("HTTP =", proj)
        @test occursin("JSON =", proj)
        @test occursin("OpenAPI =", proj)

        # End-to-end: the scaffolded package should test green on its own.
        if get(ENV, "OPENAPITEMPLATE_SKIP_INNER_TEST", "0") != "1"
            run(Cmd(
                `julia --project=. -e 'using Pkg; Pkg.test()'`;
                dir = pkg_dir,
            ))
        end
    end
end
