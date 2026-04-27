module {{PKG}}

using HTTP, JSON, OpenAPI

# Hand-written ergonomic surface
include("client/Client.jl")

export Client

end # module
