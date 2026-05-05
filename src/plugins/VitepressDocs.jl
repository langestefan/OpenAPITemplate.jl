using TOML

"""
    VitepressDocs(; deploy=true)

Scaffolds the generated package's `docs/` tree on top of
[DocumenterVitepress](https://github.com/LuxDL/DocumenterVitepress.jl):

  - `docs/Project.toml`, `docs/package.json`, `docs/make.jl`
  - `docs/src/{index,getting_started,julia_reference}.md`
  - `.github/workflows/Documentation.yml`

When `OpenAPISpec` bundled an OpenAPI spec, additionally writes:

  - `docs/src/api/index.md` — interactive REST browser via
    [`vitepress-openapi`](https://github.com/enzonotario/vitepress-openapi)
  - `docs/.vitepress/theme/index.js` — theme extension that wires the spec
    into the Vue components

`deploy=false` skips the GitHub Actions workflow (useful for private docs).
"""
Base.@kwdef struct VitepressDocs <: Plugin
    deploy::Bool = true
end

# Run after OpenAPISpec (priority 100) so we know whether codegen produced
# `spec/openapi.json`, but before Git's posthook (priority 5).
PkgTemplates.priority(::VitepressDocs, ::typeof(PkgTemplates.posthook)) = 25

function PkgTemplates.posthook(p::VitepressDocs, t::Template, pkg_dir::AbstractString)
    pkg = pkg_name(pkg_dir)
    user = String(t.user)
    has_spec = isfile(joinpath(pkg_dir, "spec", "openapi.json"))

    vars = Dict{String, String}(
        "PKG" => pkg,
        "PKG_LOWER" => lowercase(pkg),
        "PKG_UPPER" => uppercase(pkg),
        "PKG_UUID" => _read_pkg_uuid_for_docs(pkg_dir),
        "USER" => user,
    )

    docs_dir = joinpath(pkg_dir, "docs")
    src_dir = joinpath(docs_dir, "src")
    mkpath(src_dir)

    _write_docs_template(docs_dir, "Project.toml", "docs/Project.toml.tpl", vars)
    _write_docs_template(docs_dir, "package.json", "docs/package.json.tpl", vars)
    _write_docs_template(docs_dir, "make.jl", "docs/make.jl.tpl", vars)
    _write_docs_template(src_dir, "index.md", "docs/src/index.md.tpl", vars)
    _write_docs_template(src_dir, "getting_started.md", "docs/src/getting_started.md.tpl", vars)
    _write_docs_template(src_dir, "julia_reference.md", "docs/src/julia_reference.md.tpl", vars)

    if has_spec
        api_dir = joinpath(src_dir, "api")
        mkpath(api_dir)
        _write_docs_template(api_dir, "index.md", "docs/src/api/index.md.tpl", vars)
        # DocumenterVitepress reads `docs/src/.vitepress/theme/index.ts` as its
        # theme entry point (when present, the default file is skipped). Our
        # version extends the default theme *and* registers vitepress-openapi
        # so the `<OASpec />` component in docs/src/api/index.md can mount.
        theme_dir = joinpath(src_dir, ".vitepress", "theme")
        mkpath(theme_dir)
        _write_docs_template(theme_dir, "index.ts", "docs/src/.vitepress/theme/index.ts.tpl", vars)
    end

    if p.deploy
        wf_dir = joinpath(pkg_dir, ".github", "workflows")
        mkpath(wf_dir)
        _write_docs_template(wf_dir, "Documentation.yml", "docs/Documentation.yml.tpl", vars)
    end

    return nothing
end

function _write_docs_template(
        dst_dir::AbstractString,
        dst_name::AbstractString,
        tpl_subpath::AbstractString,
        vars::Dict{String, String},
    )
    src = joinpath(TEMPLATES_DIR, tpl_subpath)
    return write(
        joinpath(dst_dir, dst_name),
        _render_kv_docs(read(src, String), vars),
    )
end

function _render_kv_docs(text::AbstractString, vars::Dict{String, String})
    for (k, v) in vars
        text = replace(text, "{{$k}}" => v)
    end
    return text
end

_read_pkg_uuid_for_docs(pkg_dir::AbstractString) =
    get(
    TOML.parsefile(joinpath(pkg_dir, "Project.toml")), "uuid",
    "00000000-0000-0000-0000-000000000000"
)
