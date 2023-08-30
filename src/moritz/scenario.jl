"""
    Scenario

Scenario is defined by its `agents`, `scenes`, and `ln`.
"""
struct Scenario
    agents::AgentsDict
    scenes::ScenesDict
    ln::LaneletNetwork

    function Scenario(agents::AgentsDict, scenes::ScenesDict, ln::LaneletNetwork)
        @assert length(agents.agents) ≥ 1 && length(scenes.scenes) ≥ 2 # at least one agent and two scenes are necessary for a scenario        
        # TODO assert that all relations are feasible when constructing -- or at least no obvious errors occur!
        return new(agents, scenes, ln)
    end
end
