"""
    Reliability(; retry=true, rate_limit=true)

Phase-4 marker plugin. The actual primitives (`RetryPolicy`, `TokenBucket`,
`with_timeout`, `with_logging`, `default_middleware`, `with_defaults`) are
emitted by [`ClientLayer`](@ref) regardless — this plugin only records the
configuration on `scaffold-info.toml` so future regeneration / drift checks
preserve the maintainer's choice. Composition of the middleware stack
happens at runtime in the generated package via `default_middleware`.

The kwargs are advisory; users always have full control over the actual
stack at the call site.
"""
Base.@kwdef struct Reliability <: Plugin
    retry::Bool = true
    rate_limit::Bool = true
end
