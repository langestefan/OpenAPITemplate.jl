[deps]
Base64 = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
OpenAPI = "d5e62ea6-ddf3-4d43-8e4c-ad5e6c8bfd7d"
{{PKG}} = "{{PKG_UUID}}"
TOML = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[sources]
{{PKG}} = { path = ".." }

# Aqua and JET are NOT listed by default — Aqua is moderately heavy and JET
# pulls in Revise + JuliaInterpreter + JuliaSyntax (~1.5 GB precompile).
# Install on demand to enable the linting tests:
#
#   pkg> activate test
#   pkg> add Aqua@0.8 JET@0.11
#
# If they are missing, `test-linting.jl` detects this and emits an `@info`
# message instead of failing. To always skip linting, set
# `OPENAPI_SKIP_LINTING=1`.
