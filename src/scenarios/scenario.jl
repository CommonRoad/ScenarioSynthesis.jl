"""
    Scenario

Scenario is defined by its `actors`, and `scenes`. TODO update
"""
struct Scenario{T}
    actors::Vector{T}
    scenes::Vector{Scene}
    lsn::LaneSectionNetwork

    function Scenario() # TODO ist this dummy constructor useful? -> remove
        return new{Vehicle}(Vector{Vehicle}(), Vector{Scene}())
    end

    function Scenario(actors::Vector{T}, scenes::Vector{Scene}) where {T<:Actor}
        @assert length(actors) > 0 && length(scenes) ≥ 2 # at least one actor and two scenes are necessary for a scenario

        scenes_sorted = sort(scenes, by = x -> x.k) # scenes must be ordered according to their index k
        @assert all(diff(map(x -> x.k, scenes_sorted)) .== 1) # the index k of two succeeding scenes must increase by 1
        
        return new{T}(actors, scenes_sorted)
    end
end