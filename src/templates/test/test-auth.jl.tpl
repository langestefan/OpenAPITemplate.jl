using {{PKG}}
using Base64: base64decode
using Test

@testset "NoAuth leaves headers untouched" begin
    h = Dict{String,String}()
    {{PKG}}.apply!({{PKG}}.NoAuth(), h)
    @test isempty(h)
end

@testset "BearerToken sets Authorization" begin
    h = Dict{String,String}()
    {{PKG}}.apply!({{PKG}}.BearerToken("abc123"), h)
    @test h["Authorization"] == "Bearer abc123"
end

@testset "APIKey defaults to X-API-Key" begin
    h = Dict{String,String}()
    {{PKG}}.apply!({{PKG}}.APIKey("xyz"), h)
    @test h["X-API-Key"] == "xyz"
end

@testset "APIKey accepts custom header" begin
    h = Dict{String,String}()
    {{PKG}}.apply!({{PKG}}.APIKey("xyz"; header = "X-Custom-Key"), h)
    @test h["X-Custom-Key"] == "xyz"
    @test !haskey(h, "X-API-Key")
end

@testset "BasicAuth base64-encodes credentials" begin
    h = Dict{String,String}()
    {{PKG}}.apply!({{PKG}}.BasicAuth("alice", "s3cret"), h)
    @test startswith(h["Authorization"], "Basic ")
    payload = String(base64decode(h["Authorization"][length("Basic ")+1:end]))
    @test payload == "alice:s3cret"
end

@testset "build_pre_request_hook applies auth" begin
    hook = {{PKG}}.build_pre_request_hook({{PKG}}.BearerToken("tok"))
    h = Dict{String,String}()
    _, _, h2 = hook("/foo", nothing, h)
    @test h2["Authorization"] == "Bearer tok"
end
