using OpenAPITemplate
using Test

using Aqua: Aqua

@testset "Aqua tests" begin
    @info "...with Aqua.jl"
    Aqua.test_all(OpenAPITemplate; ambiguities = false)
end

if v"1.12" <= VERSION < v"1.13" # JET compatibility
    using JET: JET
    @testset "JET tests" begin
        @info "...with JET.jl"
        JET.test_package(OpenAPITemplate; target_modules = (OpenAPITemplate,))
    end
end
