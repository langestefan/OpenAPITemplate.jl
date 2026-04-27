module {{PKG}}

using HTTP, JSON, OpenAPI

# Generated low-level surface — DO NOT EDIT, regenerate via gen/regenerate.jl
include("api/{{API_PKG}}.jl")
using .{{API_PKG}}

# Re-export every public name from the generated module so users don't have to
# qualify with `{{API_PKG}}.`.
for n in names({{API_PKG}}; all = false)
    n === Symbol("{{API_PKG}}") && continue
    @eval export $n
end

# Hand-written ergonomic surface
include("client/auth.jl")
include("client/errors.jl")
include("client/retry.jl")
include("client/rate_limit.jl")
include("client/timeout.jl")
include("client/Client.jl")
include("client/pagination.jl")
include("client/show.jl")

export Client, Auth, NoAuth, BearerToken, APIKey, BasicAuth
export APIError, NetworkError, ClientError, ServerError, AuthError,
    RateLimitError, TimeoutError
export RetryPolicy, with_retry
export TokenBucket, acquire!, with_rate_limit
export with_timeout
export paginate_cursor, paginate_offset, paginate_pagenum

end # module
