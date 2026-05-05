using Test
using OpenAPITemplate
using TOML: TOML

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

@testset "_normalize_to_oas3! is a no-op for OAS 3 specs" begin
    mktempdir() do dir
        spec = joinpath(dir, "openapi.json")
        write(spec, """{"openapi":"3.0.1","paths":{}}""")
        before = read(spec, String)
        OpenAPITemplate._normalize_to_oas3!(spec)
        @test read(spec, String) == before
        # No backup file should be created for v3 specs.
        @test !isfile(joinpath(dir, "openapi.v2-original.json"))
    end
end

@testset "_render_kv substitutes all keys" begin
    text = "package={{PKG}} api={{API_PKG}} version={{VERSION}}"
    out = OpenAPITemplate._render_kv(
        text, Dict(
            "PKG" => "Foo",
            "API_PKG" => "FooAPI",
            "VERSION" => "1.2.3"
        )
    )
    @test out == "package=Foo api=FooAPI version=1.2.3"
end

@testset "_render_kv leaves unmatched placeholders alone" begin
    out = OpenAPITemplate._render_kv(
        "hello {{PKG}} {{UNKNOWN}}",
        Dict("PKG" => "World")
    )
    @test out == "hello World {{UNKNOWN}}"
end

@testset "_write_gen_files emits openapi-config and regenerate.jl" begin
    mktempdir() do dir
        OpenAPITemplate._write_gen_files(
            dir, "MyAPI",
            "https://example.com/openapi.json",
            "7.10.0"
        )
        cfg = read(joinpath(dir, "gen", "openapi-config.json"), String)
        @test occursin("\"packageName\": \"MyAPI\"", cfg)

        regen = read(joinpath(dir, "gen", "regenerate.jl"), String)
        @test occursin("MyAPI", regen)
        @test occursin("https://example.com/openapi.json", regen)
        @test occursin("7.10.0", regen)
    end
end

@testset "_rewrite_module_with_api renders module template" begin
    mktempdir() do dir
        mkpath(joinpath(dir, "src"))
        OpenAPITemplate._rewrite_module_with_api(dir, "MyWrapper", "MyWrapperAPI")
        src = read(joinpath(dir, "src", "MyWrapper.jl"), String)
        @test occursin("module MyWrapper", src)
        @test occursin("include(\"api/MyWrapperAPI.jl\")", src)
        @test occursin("using .MyWrapperAPI", src)
    end
end

@testset "_write_scaffold_info records spec metadata" begin
    mktempdir() do dir
        OpenAPITemplate._write_scaffold_info(dir, "https://example.com/spec.json", "7.10.0")
        path = joinpath(dir, "scaffold-info.toml")
        @test isfile(path)
        info = TOML.parsefile(path)
        @test info["spec_url"] == "https://example.com/spec.json"
        @test info["spec_path"] == "spec/openapi.json"
        @test info["generator_version"] == "7.10.0"
        @test haskey(info, "generated_at")
    end
end

@testset "_write_drift_check_workflow copies workflow file" begin
    mktempdir() do dir
        OpenAPITemplate._write_drift_check_workflow(dir)
        path = joinpath(dir, ".github", "workflows", "regen-check.yml")
        @test isfile(path)
        contents = read(path, String)
        @test occursin("OpenAPI drift check", contents)
        @test occursin("openapi-drift-check", contents)  # branch name
    end
end

@testset "_save_spec from local file with non-default name" begin
    mktempdir() do dir
        src = joinpath(dir, "weird-name.yaml")
        write(src, "openapi: 3.0.0\n")
        dst = joinpath(dir, "out", "openapi.json")
        OpenAPITemplate._save_spec(src, dst)
        @test read(dst, String) == "openapi: 3.0.0\n"
    end
end
