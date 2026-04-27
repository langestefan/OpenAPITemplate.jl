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

Phase 5 will extend this with `BrokenRecord.jl` cassette infrastructure.
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

    _write_test_file(test_dir, "Project.toml", "test/Project.toml.tpl",
                     Dict{String,String}("PKG" => pkg, "PKG_UUID" => _read_pkg_uuid(pkg_dir)))
    _write_test_file(test_dir, "runtests.jl", "test/runtests.jl.tpl",
                     Dict{String,String}("PKG" => pkg))
    _write_test_file(test_dir, "test-linting.jl", "test/test-linting.jl.tpl",
                     Dict{String,String}("PKG" => pkg))
    _write_test_file(test_dir, "test-client-construction.jl",
                     "test/test-client-construction.jl.tpl",
                     Dict{String,String}("PKG" => pkg))
    _write_test_file(test_dir, "test-auth.jl",
                     "test/test-auth.jl.tpl",
                     Dict{String,String}("PKG" => pkg))
    _write_test_file(test_dir, "test-pagination.jl",
                     "test/test-pagination.jl.tpl",
                     Dict{String,String}("PKG" => pkg))
    _write_test_file(test_dir, "test-show.jl",
                     "test/test-show.jl.tpl",
                     Dict{String,String}("PKG" => pkg))
    _write_test_file(test_dir, "test-errors.jl",
                     "test/test-errors.jl.tpl",
                     Dict{String,String}("PKG" => pkg))
    _write_test_file(test_dir, "test-retry.jl",
                     "test/test-retry.jl.tpl",
                     Dict{String,String}("PKG" => pkg))
    _write_test_file(test_dir, "test-rate-limit.jl",
                     "test/test-rate-limit.jl.tpl",
                     Dict{String,String}("PKG" => pkg))
    _write_test_file(test_dir, "test-timeout.jl",
                     "test/test-timeout.jl.tpl",
                     Dict{String,String}("PKG" => pkg))

    if has_api
        api_pkg = pkg * "API"
        _write_test_file(test_dir, "test-scaffold-metadata.jl",
                         "test/test-scaffold-metadata.jl.tpl",
                         Dict{String,String}("PKG" => pkg))
        _write_test_file(test_dir, "test-models.jl",
                         "test/test-models.jl.tpl",
                         Dict{String,String}("PKG" => pkg, "API_PKG" => api_pkg))
    end
    return nothing
end

function _write_test_file(
    test_dir::AbstractString,
    dst_name::AbstractString,
    tpl_subpath::AbstractString,
    vars::Dict{String,String},
)
    write(
        joinpath(test_dir, dst_name),
        _render_kv(
            read(joinpath(OpenAPITemplate.TEMPLATES_DIR, tpl_subpath), String),
            vars,
        ),
    )
end

_read_pkg_uuid(pkg_dir::AbstractString) =
    get(TOML.parsefile(joinpath(pkg_dir, "Project.toml")), "uuid",
        "00000000-0000-0000-0000-000000000000")
