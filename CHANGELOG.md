# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — 2026-05-05

Initial release.

### Added

- `APIWrapper(; spec_url, auth_modes, retry, rate_limit, deploy_docs)`
  template factory composing five sub-plugins on top of standard
  PkgTemplates plugins.
- **`OpenAPISpec`** — drives `openapi-generator-cli julia-client` at scaffold
  time (auto-converts Swagger 2.0 → OpenAPI 3.0 via `swagger2openapi`),
  bundles the spec at `spec/openapi.json`, writes `gen/openapi-config.json`
  and `gen/regenerate.jl`, adds `src/api/** linguist-generated=true`,
  records spec metadata in `scaffold-info.toml`, and emits an opt-in
  `regen-check.yml` weekly drift workflow.
- **`ClientLayer`** — hand-written ergonomic overlay: `Client` struct
  wrapping `OpenAPI.Clients.Client`, `Auth` hierarchy
  (`NoAuth` / `BearerToken` / `APIKey` / `BasicAuth`),
  `resolve_credentials` env-var/TOML lookup helper, lazy pagination
  iterators (`paginate_cursor`, `paginate_offset`, `paginate_pagenum`),
  pretty `show` for `OpenAPI.APIModel` types.
- **`Reliability`** primitives — `RetryPolicy` with exponential backoff +
  jitter (honours `Retry-After`), `TokenBucket` rate limiter,
  `with_timeout`, secret-redacting `with_logging`, typed `APIError`
  hierarchy (`NetworkError`, `ClientError`, `ServerError`, `AuthError`,
  `RateLimitError`, `TimeoutError`) with `check_response` mapper,
  composable `default_middleware` / `with_defaults` stack.
- **`BrokenRecordTests`** — scaffolds `test/` with auto-walking
  `runtests.jl`, opt-in Aqua/JET linting (detect-and-skip), opt-in
  BrokenRecord cassette infrastructure (`test/cassettes/`), opt-in
  Mocking helpers, plus per-component test files (auth, errors,
  middleware, pagination, retry, rate-limit, timeout, show, client
  construction, scaffold metadata, models).
- **`VitepressDocs`** — `docs/` powered by DocumenterVitepress with a
  per-tag interactive REST browser via
  [`vitepress-openapi`](https://github.com/enzonotario/vitepress-openapi)
  (one `<OAOperation>` per spec operation, grouped by tag, surfaced in
  the right-side outline). Bundled GitHub Pages deployment workflow.
- Repository CI for the meta-package itself: matrix `Test.yml`,
  fast-PR `TestOnPRs.yml`, weekly `Codegen.yml` smoke test (Java + Node),
  `Lint.yml` (prek + lychee), `CompatHelper.yml`, `ReleaseDrafter.yml`.

[0.1.0]: https://github.com/langestefan/OpenAPITemplate.jl/releases/tag/v0.1.0
