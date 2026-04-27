using {{PKG}}
using Test

using Aqua: Aqua

@testset "Aqua tests" begin
    @info "...with Aqua.jl"
    # `ambiguities=false` and `stale_deps=false` are common with OpenAPI-generated
    # surfaces that pull transitive deps via the generated module.
    Aqua.test_all({{PKG}}; ambiguities = false, stale_deps = false)
end

if v"1.12" <= VERSION < v"1.13" # JET compatibility
    using JET: JET
    @testset "JET tests" begin
        @info "...with JET.jl"
        JET.test_package({{PKG}}; target_modules = ({{PKG}},))
    end
end
