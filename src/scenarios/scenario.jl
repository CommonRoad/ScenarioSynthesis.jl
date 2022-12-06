"""
    Scenario

Scenario is defined by its `actors`, `scenes`, and `ln`.
"""
struct Scenario
    actors::ActorsDict
    scenes::ScenesDict
    ln::LaneletNetwork

    function Scenario(actors::ActorsDict, scenes::ScenesDict, ln::LaneletNetwork)
        @assert length(actors.actors) ≥ 1 && length(scenes.scenes) ≥ 2 # at least one actor and two scenes are necessary for a scenario        
        return new(actors, scenes, ln)
    end
end