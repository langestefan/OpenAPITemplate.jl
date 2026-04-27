module {{PKG}}

using HTTP, JSON, OpenAPI

# Hand-written ergonomic surface
include("client/auth.jl")
include("client/Client.jl")

export Client, Auth, NoAuth, BearerToken, APIKey, BasicAuth

end # module
