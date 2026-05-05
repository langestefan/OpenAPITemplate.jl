```@meta
CurrentModule = {{PKG}}
```

# {{PKG}}.jl

Documentation for [{{PKG}}.jl](https://github.com/{{USER}}/{{PKG}}.jl).

A Julia REST/JSON API wrapper scaffolded with
[OpenAPITemplate.jl](https://github.com/{{USER}}/OpenAPITemplate.jl).

## Quick start

```julia
using {{PKG}}

client = Client("https://api.example.com"; auth = BearerToken(ENV["{{PKG_UPPER}}_TOKEN"]))
```

See the [Getting Started](getting_started.md) guide for a worked example, or
the [Julia API Reference](julia_reference.md) for the full surface.
