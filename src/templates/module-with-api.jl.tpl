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
include("client/Client.jl")

export Client

end # module
