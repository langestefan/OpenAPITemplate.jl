using Test

# PkgTemplates' `Git` plugin's `validate` checks the global Git config for
# `user.name` and `user.email`. CI runners (and fresh dev machines) often
# don't have these set, so seed sensible defaults for the duration of the
# test process. `LibGit2.set_global_config_entry!` would persist; we use
# `git config --global` only when the value is missing.
let
    cmd(args...) = strip(read(ignorestatus(`git config --global $(args...)`), String))
    isempty(cmd("user.name")) && run(`git config --global user.name "Test User"`)
    isempty(cmd("user.email")) && run(`git config --global user.email "test@example.com"`)
end

include("linting.jl")

#=
Don't add your tests to runtests.jl. Instead, create files named

    test-title-for-my-test.jl

The file will be automatically included inside a `@testset` with title "Title For My Test".
=#
for (root, dirs, files) in walkdir(@__DIR__)
    for file in files
        if isnothing(match(r"^test-.*\.jl$", file))
            continue
        end
        title = titlecase(replace(splitext(file[6:end])[1], "-" => " "))
        @testset "$title" begin
            include(joinpath(root, file))
        end
    end
end
