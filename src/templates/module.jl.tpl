module {{PKG}}

using HTTP, JSON, OpenAPI

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
