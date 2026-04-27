#!/usr/bin/env julia
# Re-run OpenAPI codegen against the upstream spec.
# Run from the package root: `julia --project gen/regenerate.jl`.
#
# Requires Java 11+ (and Node 18+ for the `npx` wrapper). End users of the
# generated wrapper package never need either — this script is for the
# maintainer only.

using Pkg

const SPEC_URL = "{{SPEC_URL}}"
const API_PKG = "{{API_PKG}}"
const GENERATOR_VERSION = "{{GENERATOR_VERSION}}"
const NPM_WRAPPER_VERSION = "{{NPM_WRAPPER_VERSION}}"

function main()
    Sys.which("java") === nothing && error(
        "java not found on PATH. Install Java 11+ from https://adoptium.net/.",
    )

    pkg_root = dirname(@__DIR__)
    spec_local = joinpath(pkg_root, "spec", "openapi.json")
    api_target = joinpath(pkg_root, "src", "api")

    if startswith(SPEC_URL, r"^https?://"i)
        @info "Refreshing spec from $SPEC_URL"
        mkpath(dirname(spec_local))
        Pkg.PlatformEngines.download(SPEC_URL, spec_local)
    else
        isfile(SPEC_URL) || error("Spec not found: $SPEC_URL")
        cp(SPEC_URL, spec_local; force = true)
    end

    mktempdir() do tmp
        out = joinpath(tmp, "out")
        cmd = Cmd(`npx --yes @openapitools/openapi-generator-cli@$(NPM_WRAPPER_VERSION) generate
                   -i $spec_local
                   -g julia-client
                   -o $out
                   --additional-properties=packageName=$(API_PKG),exportModels=true,exportOperations=true`;
                  dir = tmp)
        env = copy(ENV)
        env["OPENAPI_GENERATOR_VERSION"] = GENERATOR_VERSION
        run(setenv(cmd, env))

        # Replace src/api/ in place.
        isdir(api_target) && rm(api_target; recursive = true)
        mkpath(api_target)
        for entry in readdir(joinpath(out, "src"); join = false)
            cp(joinpath(out, "src", entry), joinpath(api_target, entry))
        end
    end

    # Format the generated tree if JuliaFormatter is available.
    try
        @eval using JuliaFormatter
        Base.invokelatest(JuliaFormatter.format, api_target)
    catch
        @info "JuliaFormatter not installed; skipping formatting of src/api/."
    end

    # Print a quick summary of what changed.
    if Sys.which("git") !== nothing && isdir(joinpath(pkg_root, ".git"))
        run(Cmd(`git diff --stat src/api spec`; dir = pkg_root))
    end

    @info "Regeneration complete." spec = spec_local api = api_target
end

main()
