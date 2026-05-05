using {{PKG}}
using Test

# BrokenRecord lets tests record an HTTP interaction once and replay it
# deterministically afterwards. Cassettes are stored as `.bson` files in
# `test/cassettes/` and committed to the repo.
#
# Re-record a cassette: `BROKENRECORD_RECORD=1 julia --project=test test/runtests.jl`
# Force replay (CI):    `BROKENRECORD_FORCE_REPLAY=1 julia --project=test test/runtests.jl`

const _CASSETTES_DIR = joinpath(@__DIR__, "cassettes")

let id = Base.identify_package("BrokenRecord")
    if id === nothing
        @info "BrokenRecord not installed; skipping cassette tests. " *
              "`pkg> add BrokenRecord@0.4` in `test/` to enable."
    else
        BrokenRecord = Base.require(id)
        BrokenRecord.configure!(;
            path = _CASSETTES_DIR,
            ignore_headers = ["Authorization", "X-API-Key", "Cookie"],
        )
        mkpath(_CASSETTES_DIR)

        @testset "cassettes directory wired up" begin
            @test isdir(_CASSETTES_DIR)
        end

        # Add concrete cassette tests below. Example:
        #
        # @testset "list pets (cassette)" begin
        #     pets = BrokenRecord.playback("list_pets.bson") do
        #         list_pets({{PKG}}.Client("https://api.example.com"))
        #     end
        #     @test !isempty(pets)
        # end
    end
end
