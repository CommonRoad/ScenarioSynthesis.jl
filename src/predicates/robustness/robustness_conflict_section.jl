function robustness(rel::Relation{IsBeforeConflictSection}, scenario::Scenario, state::StateCurv)
    route = scenario.actors.actors[rel.actor1].route
    return route.conflict_sections[rel.conflict_section][1] - state.lon.s
end

function robustness(rel::Relation{IsOnConflictSection}, scenario::Scenario, state::StateCurv)
    route = scenario.actors.actors[rel.actor1].route
    s = state.lon.s
    s_low = route.conflict_sections[rel.conflict_section][1] 
    s_upp = route.conflict_sections[rel.conflict_section][2] 
    return (s - s_low) * (s_upp - s) 
end

function robustness(rel::Relation{IsBehindConflictSection}, scenario::Scenario, state::StateCurv)
    route = scenario.actors.actors[rel.actor1].route
    return state.lon.s - route.conflict_sections[rel.conflict_section][2]
end