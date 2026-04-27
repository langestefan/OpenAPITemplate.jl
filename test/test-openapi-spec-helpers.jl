using Test
using OpenAPITemplate

@testset "_save_spec from local file" begin
    mktempdir() do dir
        src = joinpath(dir, "src.json")
        write(src, "{}")
        dst = joinpath(dir, "out", "openapi.json")
        OpenAPITemplate._save_spec(src, dst)
        @test isfile(dst)
        @test read(dst, String) == "{}"
    end
end

@testset "_save_spec rejects unknown source" begin
    mktempdir() do dir
        @test_throws ErrorException OpenAPITemplate._save_spec(
            joinpath(dir, "does-not-exist.json"),
            joinpath(dir, "out.json"),
        )
    end
end

@testset "_add_gitattributes appends to existing file" begin
    mktempdir() do dir
        path = joinpath(dir, ".gitattributes")
        write(path, "*.jl text\n")
        OpenAPITemplate._add_gitattributes(dir)
        contents = read(path, String)
        @test occursin("*.jl text", contents)
        @test occursin("src/api/** linguist-generated=true", contents)
    end
end

@testset "_add_gitattributes is idempotent" begin
    mktempdir() do dir
        path = joinpath(dir, ".gitattributes")
        OpenAPITemplate._add_gitattributes(dir)
        OpenAPITemplate._add_gitattributes(dir)
        # Single occurrence even after two calls.
        contents = read(path, String)
        @test count("src/api/** linguist-generated=true", contents) == 1
    end
end

@testset "_add_gitattributes appends newline when missing" begin
    mktempdir() do dir
        path = joinpath(dir, ".gitattributes")
        write(path, "*.jl text")  # no trailing newline
        OpenAPITemplate._add_gitattributes(dir)
        @test endswith(read(path, String), "src/api/** linguist-generated=true\n")
    end
end
