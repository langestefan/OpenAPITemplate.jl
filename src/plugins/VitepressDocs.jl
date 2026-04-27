"""
    VitepressDocs(; deploy=true)

Phase-1 stub. Will configure DocumenterVitepress and the `vitepress-openapi`
interactive REST browser in Phase 6.
"""
Base.@kwdef struct VitepressDocs <: Plugin
    deploy::Bool = true
end
