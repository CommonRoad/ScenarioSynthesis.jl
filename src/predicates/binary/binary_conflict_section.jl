function binary(rel::Relation{IsBeforeConflictSection}, scenario::Scenario, state::StateCurv)
    route = scenario.actors.actors[rel.actor1].route
    return state.lon.s < route.conflict_sections[rel.conflict_section][1]
end

function binary(rel::Relation{IsOnConflictSection}, scenario::Scenario, state::StateCurv)
    route = scenario.actors.actors[rel.actor1].route
    return route.conflict_sections[rel.conflict_section][1] ≤ state.lon.s ≤ route.conflict_sections[rel.conflict_section][2] 
end

function binary(rel::Relation{IsBehindConflictSection}, scenario::Scenario, state::StateCurv)
    route = scenario.actors.actors[rel.actor1].route
    return route.conflict_sections[rel.conflict_section][2] < state.lon.s
end