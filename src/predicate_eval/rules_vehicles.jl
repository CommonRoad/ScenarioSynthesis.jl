function is_valid(rel::Relation{IsInFront}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    lon_dist, does_exist = lon_distance(actor1, state1.lon.s, actor2, state2.lon.s, scenario.ln)
    does_exist || return false
    
    return safety_distance(state1, state2) + actor1.len/2 + actor2.len/2 < lon_dist
end

function is_valid(rel::Relation{IsBehind}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    lon_dist, does_exist = lon_distance(actor1, state1.lon.s, actor2, state2.lon.s, scenario.ln)
    does_exist || return false
    
    return lon_dist < -safety_distance(state1, state2) - actor1.len/2 - actor2.len/2
end

function is_valid(rel::Relation{IsNextTo}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    lon_dist, does_exist = lon_distance(actor1, state1.lon.s, actor2, state2.lon.s, scenario.ln)
    does_exist || return false
    
    return -safety_distance(state1, state2) - actor1.len/2 - actor2.len/2 ≤ lon_dist ≤ safety_distance(state1, state2) + actor1.len/2 + actor2.len/2
end

@inline function safety_distance(state1::StateCurv, state2::StateCurv) # TODO maybe also consider individual accelerations? 
    return max(10.0, state1.lon.v, state2.lon.v) # safety distance in meters
end

is_valid(rel::Relation{IsFaster}, scenario::Scenario, state1::StateCurv, state2::StateCurv) = state1.lon.v > state2.lon.v # TODO remove unnecessary arguments? 