function binary(rel::Relation{IsInFront}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    lon_dist, does_exist = lon_distance(actor1, state1.lon.s, actor2, state2.lon.s, scenario.ln)
    does_exist || return false # TODO throw error instead?
    
    return position_tolerance() + actor1.len/2 + actor2.len/2 < lon_dist
end

function binary(rel::Relation{IsBehind}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    lon_dist, does_exist = lon_distance(actor1, state1.lon.s, actor2, state2.lon.s, scenario.ln)
    does_exist || return false # TODO throw error instead?
    
    return lon_dist < -position_tolerance() - actor1.len/2 - actor2.len/2
end

function binary(rel::Relation{IsNextTo}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    lon_dist, does_exist = lon_distance(actor1, state1.lon.s, actor2, state2.lon.s, scenario.ln)
    does_exist || return false # TODO throw error instead?
    
    return -position_tolerance() - actor1.len/2 - actor2.len/2 ≤ lon_dist ≤ position_tolerance() + actor1.len/2 + actor2.len/2
end

binary(rel::Relation{IsFaster}, scenario::Scenario, state1::StateCurv, state2::StateCurv) = state1.lon.v > state2.lon.v + velocity_tolerance() # TODO remove unnecessary arguments? 
binary(rel::Relation{IsSameSpeed}, scenario::Scenario, state1::StateCurv,state2::StateCurv) = state2.lon.v - velocity_tolerance() ≤ state1.lon.v ≤ state2.lon.v + velocity_tolerance() # # TODO remove unnecessary arguments? 
binary(rel::Relation{IsSlower}, scenario::Scenario, state1::StateCurv, state2::StateCurv) = state1.lon.v < state2.lon.v - velocity_tolerance() # TODO remove unnecessary arguments? 
binary(rel::Relation{IsStop}, scenario::Scenario, state::StateCurv) = state.lon.v < velocity_tolerance()