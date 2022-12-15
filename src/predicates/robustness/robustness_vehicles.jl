# TODO use other metric than safety distance for vehicle relations? 

function robustness(rel::Relation{IsInFront}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    lon_dist, does_exist = lon_distance(actor1, state1.lon.s, actor2, state2.lon.s, scenario.ln)
    does_exist || return -1e3 # TODO does return value make sense? Throw error instead?
    
    return lon_dist - (safety_distance(state1, state2) + actor1.len/2 + actor2.len/2)
end

function robustness(rel::Relation{IsNextTo}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    lon_dist, does_exist = lon_distance(actor1, state1.lon.s, actor2, state2.lon.s, scenario.ln)
    does_exist || return -1e3

    return (safety_distance(state1, state2) + actor1.len/2 + actor2.len/2 - abs(lon_dist))^2 # TODO does square make sense? 
end

function robustness(rel::Relation{IsBehind}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    lon_dist, does_exist = lon_distance(actor1, state1.lon.s, actor2, state2.lon.s, scenario.ln)
    does_exist || return -1e3
    
    return (safety_distance(state1, state2) + actor1.len/2 + actor2.len/2) - lon_dist
end

function robustness(rel::Relation{IsFaster}, state1::StateCurv, state2::StateCurv)
    return state1.lon.v - state2.lon.v
end