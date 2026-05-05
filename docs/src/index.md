```@raw html
---
layout: home

hero:
  name: "OpenAPITemplate.jl"
  text: "Scaffold Julia REST/JSON API wrappers"
  tagline: A PkgTemplates plugin that produces ergonomic, batteries-included Julia clients from any OpenAPI 2.0 or 3.x spec.
  actions:
    - theme: brand
      text: Quick Start
      link: /quickstart
    - theme: alt
      text: Architecture
      link: /architecture
    - theme: alt
      text: View on GitHub
      link: https://github.com/langestefan/OpenAPITemplate.jl

features:
  - icon: 🧬
    title: Two-layer architecture
    details: Generated `src/api/` (committed Julia, no Java at runtime) plus a hand-written `src/client/` overlay with auth, middleware, pagination.
    link: /architecture
  - icon: 🔁
    title: Composable reliability
    details: RetryPolicy, TokenBucket, with_timeout, secret-redacting logging, typed APIError hierarchy — wired together by default_middleware / with_defaults.
    link: /api
  - icon: 📚
    title: Interactive docs included
    details: Each scaffolded package gets a DocumenterVitepress site with an interactive REST API browser via vitepress-openapi.
    link: /plugins
---
```

```@raw html
<p style="margin-bottom:2cm"></p>

<div class="vp-doc" style="width:80%; margin:auto">
<h2>What it does</h2>
<p>
<code>OpenAPITemplate.jl</code> drives the OpenAPI Generator's
<code>julia-client</code> at scaffold time and layers a hand-written
ergonomic surface on top. The result: <code>Pkg.test</code>-passing
REST/JSON wrapper packages with auth strategies, retry/rate-limit/timeout
middleware, recorded HTTP tests, and an interactive docs site — all from
one <code>Template(...)</code> call.
</p>
<h2>Quick start</h2>
```

```julia
using PkgTemplates, OpenAPITemplate

t = Template(;
    user = "your-username",
    dir  = pwd(),
    plugins = APIWrapper(;
        spec_url = "https://petstore.swagger.io/v2/swagger.json",
    ),
)
t("PetstoreClient")
```

```@raw html
<p>
The Swagger 2.0 spec is auto-converted to OpenAPI 3.0 in place; codegen
runs once; <code>src/api/</code>, <code>src/client/</code>, the test tree,
and the docs site are written under <code>./PetstoreClient/</code>. End
users of the generated package never need Java or Node.
</p>
</div>
```
