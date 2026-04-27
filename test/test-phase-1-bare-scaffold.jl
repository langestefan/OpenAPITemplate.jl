using Test
using OpenAPITemplate
using PkgTemplates

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

    module_src = read(joinpath(pkg_dir, "src", "ScratchAPI.jl"), String)
    @test occursin("include(\"client/Client.jl\")", module_src)
    @test occursin("using HTTP, JSON, OpenAPI", module_src)
    # No spec → no api/ wiring.
    @test !occursin("include(\"api/", module_src)
    @test !isdir(joinpath(pkg_dir, "src", "api"))
    @test !isdir(joinpath(pkg_dir, "spec"))

    proj = read(joinpath(pkg_dir, "Project.toml"), String)
    @test occursin("HTTP =", proj)
    @test occursin("JSON =", proj)
    @test occursin("OpenAPI =", proj)

    if get(ENV, "OPENAPITEMPLATE_SKIP_INNER_TEST", "0") != "1"
        env = copy(ENV)
        # Strip parent Pkg.test()'s JULIA_LOAD_PATH/JULIA_PROJECT so the inner
        # `--project=.` resolves cleanly against stdlib.
        delete!(env, "JULIA_LOAD_PATH")
        delete!(env, "JULIA_PROJECT")
        run(setenv(Cmd(
            `julia --project=. -e 'using Pkg; Pkg.test()'`;
            dir = pkg_dir,
        ), env))
    end
end
