```@meta
CurrentModule = OpenAPITemplate
```

# Plugins

[`APIWrapper`](@ref) composes five sub-plugins. Each is a regular
`PkgTemplates.Plugin` and can be used standalone if you only want part
of the scaffold. Full docstrings live on the [Public API](api.md) page;
this page describes how each one fits into the pipeline.

## [`OpenAPISpec`](@ref)

Drives `openapi-generator-cli julia-client`. Skipped entirely when
`spec_url === nothing`. When set, it:

- Saves the spec to `spec/openapi.json`.
- If the spec is Swagger 2.0, [normalises it to OpenAPI 3.0](spec-conversion.md)
  in place via `npx swagger2openapi`.
- Writes `gen/openapi-config.json` and `gen/regenerate.jl` for later
  refreshes.
- Runs the generator once, populating `src/api/`.
- Adds `src/api/** linguist-generated=true` to `.gitattributes`.
- Records spec URL, generator version, and timestamp in
  `scaffold-info.toml`.
- Drops a `.github/workflows/regen-check.yml` workflow that re-runs
  codegen weekly and opens a PR if the upstream spec drifted.

## [`ClientLayer`](@ref)

Writes the hand-written `src/client/` overlay (auth, errors, retry,
rate-limit, timeout, logging, middleware, pagination, show), the
umbrella module file, the rendered `README.md`, and contributes
`.gitignore` entries (`.DS_Store`, `*.rej`, `node_modules/`,
`docs/build/`, `docs/.vitepress/cache/` etc.) to the `Git` plugin via
`PkgTemplates.gitignore(::ClientLayer)`.

Adds `Base64`, `HTTP`, `JSON`, `Logging`, `OpenAPI`, `TOML` to the
generated package's `Project.toml` runtime deps.

## [`Reliability`](@ref)

Marker plugin. The retry / rate-limit / timeout / logging primitives
are emitted by `ClientLayer` regardless; this plugin's kwargs
(`retry`, `rate_limit`) are reserved for recording on
`scaffold-info.toml` so future regenerations preserve the maintainer's
choice. Composition of the actual middleware stack happens at runtime
in the generated package via `default_middleware` / `with_defaults`.

## [`BrokenRecordTests`](@ref)

Owns the generated package's `test/` tree. Replaces the default
PkgTemplates `Tests` plugin (disabled by `APIWrapper`). Emits:

- `test/Project.toml`, `test/runtests.jl` (auto-walking)
- Per-component test files: `test-auth.jl`, `test-client-construction.jl`,
  `test-errors.jl`, `test-middleware.jl`, `test-pagination.jl`,
  `test-rate-limit.jl`, `test-retry.jl`, `test-show.jl`,
  `test-timeout.jl`
- Opt-in skeletons: `test-cassettes.jl` (BrokenRecord), `test-mocking.jl`
  (Mocking.jl), `test-linting.jl` (Aqua + JET, detect-and-skip)
- `test/cassettes/.gitkeep` so the cassette directory exists from day one
- `test-scaffold-metadata.jl` and `test-models.jl` (only when codegen
  ran)

## [`VitepressDocs`](@ref)

DocumenterVitepress site with a per-tag interactive REST API browser
backed by [`vitepress-openapi`](https://github.com/enzonotario/vitepress-openapi).
At `make.jl` build time, walks `spec/openapi.json` and emits one
markdown page per spec tag, each containing one `<OAOperation>` per
operation as a `##` heading — letting VitePress's right-side outline
list every endpoint.

Bundles a GitHub Pages deployment workflow when `deploy=true`.

## Composing your own template

`APIWrapper` is just a `Vector{<:Plugin}` factory. To customise — e.g.
swap `Codecov` for a different coverage uploader, or omit
`VitepressDocs` for a docs-less scaffold — copy the body of
[`APIWrapper`](@ref) and adjust the list:

```julia
function MyAPIWrapper(; spec_url = nothing)
    return Any[
        !PkgTemplates.Tests,
        ProjectFile(), SrcDir(), Readme(), License(), Git(),
        Formatter(), GitHubActions(), CompatHelper(), TagBot(),
        OpenAPISpec(; spec_url),
        ClientLayer(),
        Reliability(),
        BrokenRecordTests(),
        # VitepressDocs(),  # ← omit
    ]
end

t = Template(; user = "me", dir = pwd(), plugins = MyAPIWrapper())
```

Each sub-plugin is fully reusable on its own and a no-op when its
preconditions aren't met (e.g. `OpenAPISpec` without `spec_url`).
