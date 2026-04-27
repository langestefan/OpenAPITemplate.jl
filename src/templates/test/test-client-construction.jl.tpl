using {{PKG}}
using OpenAPI
using Test

@testset "Client construction" begin
    c = {{PKG}}.Client("https://example.test/api")
    @test c isa {{PKG}}.Client
    @test c.base_url == "https://example.test/api"
    @test c.auth isa {{PKG}}.NoAuth
    @test c.inner isa OpenAPI.Clients.Client
end

@testset "Client with auth" begin
    c = {{PKG}}.Client("https://example.test"; auth = {{PKG}}.BearerToken("abc"))
    @test c.auth isa {{PKG}}.BearerToken
    @test c.auth.token == "abc"
end
