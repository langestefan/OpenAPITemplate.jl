using Test
using OpenAPITemplate
using PkgTemplates

if get(ENV, "OPENAPITEMPLATE_RUN_CODEGEN", "0") != "1"
    @info "Skipping Phase 2 codegen tests; set OPENAPITEMPLATE_RUN_CODEGEN=1 to enable."
else
    mktempdir() do dir
        t = Template(;
            user = "testuser",
            dir = dir,
            plugins = APIWrapper(;
                spec_url = "https://petstore3.swagger.io/api/v3/openapi.json",
            ),
            interactive = false,
        )
        t("PetstoreClient")

        pkg_dir = joinpath(dir, "PetstoreClient")
        api_dir = joinpath(pkg_dir, "src", "api")

        @test isfile(joinpath(pkg_dir, "spec", "openapi.json"))
        @test isfile(joinpath(pkg_dir, "gen", "openapi-config.json"))
        @test isfile(joinpath(pkg_dir, "gen", "regenerate.jl"))
        @test isfile(joinpath(pkg_dir, "scaffold-info.toml"))
        @test isdir(api_dir)
        @test isfile(joinpath(api_dir, "PetstoreClientAPI.jl"))
        @test isfile(joinpath(api_dir, "modelincludes.jl"))
        @test !isempty(readdir(joinpath(api_dir, "models")))
        @test !isempty(readdir(joinpath(api_dir, "apis")))

        gitattr = read(joinpath(pkg_dir, ".gitattributes"), String)
        @test occursin("src/api/** linguist-generated=true", gitattr)

        module_src = read(joinpath(pkg_dir, "src", "PetstoreClient.jl"), String)
        @test occursin("include(\"api/PetstoreClientAPI.jl\")", module_src)
        @test occursin("using .PetstoreClientAPI", module_src)

        # Java-free: load the package without `java` on PATH.
        load_cmd = `julia --project=. -e 'using PetstoreClient; @assert isdefined(PetstoreClient, :Pet); @assert isdefined(PetstoreClient, :PetApi); println("ok")'`
        env = copy(ENV)
        env["PATH"] = join(filter(p -> !occursin("java", lowercase(p)),
                                  split(get(env, "PATH", ""), ':')), ':')
        delete!(env, "JAVA_HOME")
        delete!(env, "JULIA_LOAD_PATH")
        delete!(env, "JULIA_PROJECT")
        run(setenv(Cmd(load_cmd; dir = pkg_dir), env))

        if get(ENV, "OPENAPITEMPLATE_SKIP_INNER_TEST", "0") != "1"
            test_env = copy(ENV)
            delete!(test_env, "JULIA_LOAD_PATH")
            delete!(test_env, "JULIA_PROJECT")
            run(setenv(Cmd(
                `julia --project=. -e 'using Pkg; Pkg.test()'`;
                dir = pkg_dir,
            ), test_env))
        end
    end
end
