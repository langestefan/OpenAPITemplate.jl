"""
    Reliability(; retry=true, rate_limit=true)

Phase-1 stub. Will install retry, rate-limit, timeout middleware and the
`APIError` hierarchy in Phase 4.
"""
Base.@kwdef struct Reliability <: Plugin
    retry::Bool = true
    rate_limit::Bool = true
end
