module {{PKG}}

using HTTP, JSON, OpenAPI

# Hand-written ergonomic surface
include("client/auth.jl")
include("client/Client.jl")
include("client/pagination.jl")
include("client/show.jl")

export Client, Auth, NoAuth, BearerToken, APIKey, BasicAuth
export paginate_cursor, paginate_offset, paginate_pagenum

end # module
