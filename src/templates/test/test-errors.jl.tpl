using {{PKG}}
using Test

@testset "Error type hierarchy" begin
    @test {{PKG}}.NetworkError(ErrorException("dns")) isa {{PKG}}.APIError
    @test {{PKG}}.ClientError(404, "not found") isa {{PKG}}.APIError
    @test {{PKG}}.ServerError(500, "boom") isa {{PKG}}.APIError
    @test {{PKG}}.AuthError(401, "nope") isa {{PKG}}.APIError
    @test {{PKG}}.RateLimitError(; retry_after = 5.0) isa {{PKG}}.APIError
    @test {{PKG}}.TimeoutError(:read) isa {{PKG}}.APIError
end

@testset "parse_retry_after" begin
    @test {{PKG}}.parse_retry_after("5") == 5.0
    @test {{PKG}}.parse_retry_after(" 12 ") == 12.0
    @test {{PKG}}.parse_retry_after("Wed, 21 Oct 2015 07:28:00 GMT") === nothing
    @test {{PKG}}.parse_retry_after("") === nothing
    @test {{PKG}}.parse_retry_after(nothing) === nothing
end

@testset "check_response 2xx returns nothing" begin
    for s in (200, 201, 204, 299)
        @test {{PKG}}.check_response(s, "") === nothing
    end
end

@testset "check_response classifies by status" begin
    @test_throws {{PKG}}.AuthError {{PKG}}.check_response(401, "")
    @test_throws {{PKG}}.AuthError {{PKG}}.check_response(403, "")
    @test_throws {{PKG}}.ClientError {{PKG}}.check_response(404, "missing")
    @test_throws {{PKG}}.ServerError {{PKG}}.check_response(503, "")
    @test_throws {{PKG}}.ClientError {{PKG}}.check_response(600, "weird")
end

@testset "check_response 429 surfaces RateLimitError" begin
    headers = Dict("Retry-After" => "7")
    err = try
        {{PKG}}.check_response(429, "", headers)
        nothing
    catch e
        e
    end
    @test err isa {{PKG}}.RateLimitError
    @test err.retry_after == 7.0
end
