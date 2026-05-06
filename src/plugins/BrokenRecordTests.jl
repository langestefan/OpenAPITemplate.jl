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

    # Linting tests load Aqua and JET via `Base.require` so they detect-and-skip
    # if absent — but the default scaffold ships with both available so the
    # `test-linting.jl` checks actually run. End users who want to skip can set
    # `OPENAPI_SKIP_LINTING=1` (handled in `runtests.jl`) or `pkg> rm` them.
    _add_test_deps(
        test_dir, [
            (
                name = "Aqua",
                uuid = "4c88cf16-eb10-579e-8560-4a9242c79595",
                compat = "0.8",
            ),
            (
                name = "JET",
                uuid = "c3a54625-cd67-489e-a8e7-0a5a0ff4e31b",
                compat = "0.9, 0.10, 0.11",
            ),
        ]
    )

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

    # Patch the CI workflow PkgTemplates' GitHubActions plugin generated so
    # that a Julia pre-release failure doesn't gate merges. JET is the usual
    # culprit: it tracks Julia minor versions tightly and a brand-new pre
    # often has no compatible JET release yet, which makes Pkg resolution
    # in `Pkg.test` unsatisfiable.
    _allow_pre_to_fail(joinpath(pkg_dir, ".github", "workflows", "CI.yml"))
    return nothing
end

# Inject `continue-on-error: ${{ matrix.version == 'pre' }}` onto the
# `julia-actions/julia-runtest@v1` step. Idempotent and a no-op if the file
# is missing or the step is absent (e.g. user disabled GitHubActions).
function _allow_pre_to_fail(ci_path::AbstractString)
    isfile(ci_path) || return nothing
    src = read(ci_path, String)
    occursin("continue-on-error: \${{ matrix.version == 'pre' }}", src) &&
        return nothing
    needle = "      - uses: julia-actions/julia-runtest@v1"
    occursin(needle, src) || return nothing
    replacement = needle * """\n        # JET tracks Julia minor versions tightly and may not yet ship support
        # for the current pre-release. Run the suite anyway (we want the early
        # warning) but don't gate merges on a Julia-pre failure.
        continue-on-error: \${{ matrix.version == 'pre' }}"""
    return write(ci_path, replace(src, needle => replacement; count = 1))
end

# Adds entries to `test/Project.toml`'s `[deps]` and optionally `[compat]`.
# Each NamedTuple must have `name` and `uuid`; a `compat` field is honoured
# when present and pins the version range.
function _add_test_deps(
        test_dir::AbstractString,
        deps::Vector{<:NamedTuple},
    )
    path = joinpath(test_dir, "Project.toml")
    toml = TOML.parsefile(path)
    deps_table = get!(toml, "deps", Dict{String, Any}())
    compat_table = get!(toml, "compat", Dict{String, Any}())
    for d in deps
        deps_table[d.name] = d.uuid
        if hasproperty(d, :compat) && d.compat !== nothing
            compat_table[d.name] = d.compat
        end
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
