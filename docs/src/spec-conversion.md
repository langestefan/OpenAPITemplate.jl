```@meta
CurrentModule = OpenAPITemplate
```

# Swagger 2.0 → OpenAPI 3.0 conversion

The `OpenAPISpec` plugin accepts both Swagger 2.0 and OpenAPI 3.x
specs. Swagger 2.0 specs are normalised to OpenAPI 3.0 in place.

## Why

Three layers of the scaffold consume the spec, and they have different
version support:

| Layer | OAS 2.0 | OAS 3.x |
| --- | --- | --- |
| `openapi-generator-cli julia-client` (codegen) | ✅ | ✅ |
| Bundled `spec/openapi.json` | (saved as-is) | (saved as-is) |
| `vitepress-openapi` (docs interactive browser) | ❌ — silently empty | ✅ |

If we left the spec as 2.0, the docs site would render the page chrome
but no endpoints. So when a Swagger 2.0 spec is detected, the plugin
runs `npx swagger2openapi` over it before anything else.

## How

After `_save_spec` writes the original to `spec/openapi.json`, the
plugin scans the first 1 KB for a top-level `"swagger": "2.x"` key:

- If absent (or `"openapi": "3"` is present) — no-op.
- If present — copy `spec/openapi.json` to `spec/openapi.v2-original.json`,
  then run `npx --yes swagger2openapi@7.0.8 spec/openapi.json -o spec/openapi.json`
  to overwrite in place. An `@info` log records what happened.

After conversion:

- `spec/openapi.json` is OAS 3.0.x
- `spec/openapi.v2-original.json` preserves the original for reference
- Codegen runs against the converted spec (the generator handles both,
  but using the converted form keeps a single source of truth)
- The docs site picks up the converted form via
  `cp(spec/openapi.json -> docs/src/public/openapi.json)` in `make.jl`

## Failure modes

- **`npx` not on PATH** — the plugin throws a friendly error pointing
  at the [Node installation page](https://nodejs.org/). `swagger2openapi`
  is the only Node dep needed for v2 conversion (codegen also uses
  `npx` to run `openapi-generator-cli`, so Node is needed for both).
- **Spec is malformed** — `swagger2openapi` exits non-zero and the
  plugin re-throws. The original v2 file is still on disk; nothing has
  been overwritten yet because the conversion is the last write step.

## Disabling the conversion

If you want to keep a Swagger 2.0 spec untouched (e.g. you don't ship
docs and prefer to feed the original to codegen), drop the
`OpenAPISpec` plugin from your template and hand-roll the few file
writes you need. `OpenAPISpec` doesn't currently expose a
`convert_swagger=false` knob — file an issue if you need one.
