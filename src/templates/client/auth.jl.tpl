using Base64: base64encode

"""
    Auth

Abstract supertype for authentication strategies. Concrete subtypes are
applied to outgoing requests via [`apply!`](@ref) and composed into a
`pre_request_hook` for `OpenAPI.Clients.Client` by [`build_pre_request_hook`](@ref).
"""
abstract type Auth end

"""
    NoAuth()

Pass-through auth: leaves request headers untouched.
"""
struct NoAuth <: Auth end

"""
    BearerToken(token)

Sets `Authorization: Bearer <token>`.
"""
struct BearerToken <: Auth
    token::String
end

"""
    APIKey(key; header="X-API-Key")

Sets `<header>: <key>`. Works for any header-based API-key scheme.
"""
struct APIKey <: Auth
    key::String
    header::String
end
APIKey(key::AbstractString; header::AbstractString = "X-API-Key") =
    APIKey(String(key), String(header))

"""
    BasicAuth(username, password)

Sets `Authorization: Basic <base64(user:pass)>`.
"""
struct BasicAuth <: Auth
    username::String
    password::String
end

"""
    apply!(auth::Auth, headers::Dict{String,String}) -> Nothing

Inject credentials into the outgoing request headers.
"""
apply!(::NoAuth, ::Dict{String,String}) = nothing

function apply!(a::BearerToken, headers::Dict{String,String})
    headers["Authorization"] = "Bearer " * a.token
    return nothing
end

function apply!(a::APIKey, headers::Dict{String,String})
    headers[a.header] = a.key
    return nothing
end

function apply!(a::BasicAuth, headers::Dict{String,String})
    creds = base64encode(a.username * ":" * a.password)
    headers["Authorization"] = "Basic " * creds
    return nothing
end

"""
    build_pre_request_hook(auth) -> Function

Build the `pre_request_hook` accepted by `OpenAPI.Clients.Client`. The hook
implements both required signatures: a `Ctx`-only pass-through and a
`(resource, body, headers)` form that calls [`apply!`](@ref) on `auth`.
"""
function build_pre_request_hook(auth::Auth)
    hook(ctx) = ctx
    function hook(resource::AbstractString, body, headers::Dict{String,String})
        apply!(auth, headers)
        return resource, body, headers
    end
    return hook
end
