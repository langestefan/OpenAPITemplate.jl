using TOML: TOML

"""
    BrokenRecordTests()

Scaffolds the generated package's test tree:

  - `test/Project.toml` declaring `Test`, `Aqua`, `JET`, plus the package itself
    via `[sources]` (Julia 1.11+).
  - `test/runtests.jl` — auto-walker that includes any `test-*.jl` file as a
    `@testset` named after the file.
  - `test/linting.jl` — `Aqua.test_all` and `JET.test_package`.
  - `test/test-client-construction.jl` — sanity test for the hand-written
    `Client` overlay.
  - `test/test-scaffold-metadata.jl` — verifies `scaffold-info.toml` and
    bundled spec (only emitted when `OpenAPISpec` ran codegen).
  - `test/test-models.jl` — round-trips a generated model through JSON (only
    emitted when codegen ran).

An empty `test/cassettes/` directory and detect-and-skip `test-cassettes.jl`
/ `test-mocking.jl` files are emitted up front so adding `BrokenRecord` or
`Mocking` later only requires `pkg> add` — no further scaffolding.
"""
Base.@kwdef struct BrokenRecordTests <: Plugin end

# Run after OpenAPISpec (priority 100) so we know whether codegen produced
# `src/api/`, but before Git's posthook (priority 5).
PkgTemplates.priority(::BrokenRecordTests, ::typeof(PkgTemplates.posthook)) = 50

function PkgTemplates.posthook(::BrokenRecordTests, ::Template, pkg_dir::AbstractString)
    pkg = pkg_name(pkg_dir)
    has_api = isdir(joinpath(pkg_dir, "src", "api"))

    test_dir = joinpath(pkg_dir, "test")
    mkpath(test_dir)

    _write_test_file(
        test_dir, "Project.toml", "test/Project.toml.tpl",
        Dict{String, String}("PKG" => pkg, "PKG_UUID" => _read_pkg_uuid(pkg_dir))
    )
    _write_test_file(
        test_dir, "runtests.jl", "test/runtests.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-linting.jl", "test/test-linting.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-client-construction.jl",
        "test/test-client-construction.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-auth.jl",
        "test/test-auth.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-pagination.jl",
        "test/test-pagination.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-show.jl",
        "test/test-show.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-errors.jl",
        "test/test-errors.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-retry.jl",
        "test/test-retry.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-rate-limit.jl",
        "test/test-rate-limit.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-timeout.jl",
        "test/test-timeout.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-middleware.jl",
        "test/test-middleware.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-cassettes.jl",
        "test/test-cassettes.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    _write_test_file(
        test_dir, "test-mocking.jl",
        "test/test-mocking.jl.tpl",
        Dict{String, String}("PKG" => pkg)
    )
    # `test/cassettes/` is the BrokenRecord storage dir. Add a `.gitkeep`
    # so the directory exists even before any cassettes have been recorded.
    cassette_dir = joinpath(test_dir, "cassettes")
    mkpath(cassette_dir)
    write(joinpath(cassette_dir, ".gitkeep"), "")

    if has_api
        api_pkg = pkg * "API"
        _write_test_file(
            test_dir, "test-scaffold-metadata.jl",
            "test/test-scaffold-metadata.jl.tpl",
            Dict{String, String}("PKG" => pkg)
        )
        _write_test_file(
            test_dir, "test-models.jl",
            "test/test-models.jl.tpl",
            Dict{String, String}("PKG" => pkg, "API_PKG" => api_pkg)
        )
        # Mirror codegen-time runtime deps that aren't already in the test
        # template into `test/Project.toml`. The package's own Project.toml
        # gets these from `OpenAPISpec._add_codegen_deps`, but the test env
        # is a sibling project and needs its own [deps] entries — otherwise
        # `using TimeZones` from a test file fails on Julia 1.10 with
        # "Package TimeZones not found in current path."
        _add_test_deps(
            test_dir, [
                (name = "TimeZones", uuid = "f269a46b-ccf7-5d73-abea-4c690281aa53"),
            ]
        )
    end
    return nothing
end

function _add_test_deps(
        test_dir::AbstractString,
        deps::Vector{<:NamedTuple{(:name, :uuid)}},
    )
    path = joinpath(test_dir, "Project.toml")
    toml = TOML.parsefile(path)
    deps_table = get!(toml, "deps", Dict{String, Any}())
    for d in deps
        deps_table[d.name] = d.uuid
    end
    return open(path, "w") do io
        TOML.print(io, toml; sorted = true)
    end
end

function _write_test_file(
        test_dir::AbstractString,
        dst_name::AbstractString,
        tpl_subpath::AbstractString,
        vars::Dict{String, String},
    )
    return write(
        joinpath(test_dir, dst_name),
        _render_kv(
            read(joinpath(TEMPLATES_DIR, tpl_subpath), String),
            vars,
        ),
    )
end

_read_pkg_uuid(pkg_dir::AbstractString) =
    get(
    TOML.parsefile(joinpath(pkg_dir, "Project.toml")), "uuid",
    "00000000-0000-0000-0000-000000000000"
)
