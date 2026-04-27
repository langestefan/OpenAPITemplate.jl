"""
    Client(base_url::AbstractString)

Bare client struct. Phase 3 will add auth, middleware, and the wrapped
`OpenAPI.Clients.Client` instance.
"""
struct Client
    base_url::String
end
