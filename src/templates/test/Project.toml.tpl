[deps]
Base64 = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
OpenAPI = "d5e62ea6-ddf3-4d43-8e4c-ad5e6c8bfd7d"
TOML = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

# `Dates` is a stdlib but Julia 1.10 still requires it in [deps] when imported
# from any non-default project. Listed unconditionally — generated wrappers
# almost always interact with timestamps, and stdlib deps cost nothing.
# `TimeZones` is added by `OpenAPISpec`'s posthook only when codegen ran,
# matching how it appears in the package's own Project.toml.

# Note: the package being tested ({{PKG}}) is NOT listed here.
# `Pkg.test` injects it into the test sandbox automatically via `develop`
# on every Julia version. Listing it would require `[sources]` to point
# at the parent path — and `[sources]` is a Julia 1.11+ feature, ignored
# by 1.10, which would then try to resolve {{PKG}} from the registry and
# fail with "has no known versions".

# Aqua and JET are added by `BrokenRecordTests`'s posthook so the linting
# tests in `test-linting.jl` actually run on every scaffolded package. To
# skip linting (e.g. on a slow CI runner), set `OPENAPI_SKIP_LINTING=1` —
# `runtests.jl` honours that flag without touching the deps. To drop them
# entirely:
#
#   pkg> activate test
#   pkg> rm Aqua JET
#
# `test-linting.jl` uses `Base.identify_package` so the deletion is
# graceful — the testset emits an `@info` and skips rather than failing.
#
# BrokenRecord, Mocking, and ReTestItems are opt-in: Aqua is light, JET
# is acceptable, but BrokenRecord/Mocking/ReTestItems are heavier and
# rarely all wanted. Install when you want cassette playback / mocked
# HTTP / parallel test items:
#
#   pkg> activate test
#   pkg> add BrokenRecord@0.1 Mocking@0.8 ReTestItems@1
#
# `test-cassettes.jl` and `test-mocking.jl` detect-and-skip when the deps
# are missing.
