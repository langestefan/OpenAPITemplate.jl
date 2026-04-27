using {{PKG}}
using Test

@testset "Client struct" begin
    c = {{PKG}}.Client("https://example.test/api")
    @test c isa {{PKG}}.Client
    @test c.base_url == "https://example.test/api"
end
