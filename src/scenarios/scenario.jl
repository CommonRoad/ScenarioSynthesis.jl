"""
    Scenario

Scenario is defined by its `actors`, `scenes`, and `ln`.
"""
struct Scenario
    actors::ActorDict
    scenes::ScenesDict
    ln::LaneletNetwork

    function Scenario(actors::Dict{ActorID, Actor}, scenes::Dict{SceneID, Scene}, ln::LaneletNetwork)
        @assert length(actors) ≥ 1 && length(scenes) ≥ 2 # at least one actor and two scenes are necessary for a scenario        
        return new(actors, scenes_sorted, ln)
    end
end