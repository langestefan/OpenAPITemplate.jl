"""
    PreCommitChecks() <: Plugin

Drop-in code-quality scaffolding: copies a curated `.pre-commit-config.yaml`
plus the supporting tool configs (`.typos.toml`, `.lychee.toml`,
`.yamlfmt.yml`, `.yamllint.yml`, `.markdownlint.yaml`) and the matching
GitHub Actions workflows (`Lint.yml`, `Spelling.yml`, `PreCommitUpdate.yml`)
into the generated package.

The pre-commit set runs the standard `pre-commit-hooks` cleaners plus
**runic** (Julia formatter), **ExplicitImports.jl** checks, **typos**
(spell-check), **markdownlint**, **yamlfmt**, and **yamllint**. Generated
`src/api/` is excluded everywhere — it's owned by `openapi-generator` and
reformatting it would diverge from what `gen/regenerate.jl` produces.

Tooling needed locally:
  - [`prek`](https://github.com/j178/prek) (Rust port of pre-commit) or
    `pre-commit` (Python) — `prek run -a` runs every hook over the tree.
  - Hooks themselves are auto-installed on first run.

The `PreCommitUpdate.yml` workflow opens a chore-PR every 7 days that
re-pins each `rev:` to the latest tag, keeping the toolchain fresh
without manual bumps.
"""
struct PreCommitChecks <: Plugin end

# Run after the rest of the scaffold has populated `.github/workflows/`
# (Codecov / CompatHelper / TagBot etc.) so we can drop our extra
# workflow files alongside theirs.
PkgTemplates.priority(::PreCommitChecks, ::typeof(PkgTemplates.posthook)) = 50

const _PRECOMMIT_TPL_DIR = joinpath(TEMPLATES_DIR, "precommit")

# Filename in the templates dir → destination relative to the package root.
# Keys end in `.tpl`; the destination drops that suffix.
const _PRECOMMIT_FILES = (
    (".pre-commit-config.yaml.tpl", ".pre-commit-config.yaml"),
    (".typos.toml.tpl",             ".typos.toml"),
    (".lychee.toml.tpl",            ".lychee.toml"),
    (".yamlfmt.yml.tpl",            ".yamlfmt.yml"),
    (".yamllint.yml.tpl",           ".yamllint.yml"),
    (".markdownlint.yaml.tpl",      ".markdownlint.yaml"),
)

const _PRECOMMIT_WORKFLOWS = (
    "Lint.yml.tpl",
    "Spelling.yml.tpl",
    "PreCommitUpdate.yml.tpl",
)

function PkgTemplates.posthook(::PreCommitChecks, ::Template, pkg_dir::AbstractString)
    for (src_name, dst_name) in _PRECOMMIT_FILES
        cp(
            joinpath(_PRECOMMIT_TPL_DIR, src_name),
            joinpath(pkg_dir, dst_name);
            force = true,
        )
    end

    workflow_dir = joinpath(pkg_dir, ".github", "workflows")
    mkpath(workflow_dir)
    for src_name in _PRECOMMIT_WORKFLOWS
        dst_name = replace(src_name, r"\.tpl$" => "")
        cp(
            joinpath(_PRECOMMIT_TPL_DIR, src_name),
            joinpath(workflow_dir, dst_name);
            force = true,
        )
    end
    return nothing
end
