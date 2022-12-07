function is_valid(rel::Relation{IsOnLanelet}, scenario::Scenario, state::StateCurv)
    actor = scenario.actors.actors[rel.actor1]

    ltid = LaneletID(actor, state, scenario.ln)

    return rel.lanelet == ltid
end

function is_valid(rel::Relation{IsRoutesMerge}, scenario::Scenario)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    # checking whether any lanelets are identical
    @inbounds for rele in actor1.route.route
        in(rele, actor2.route.route) && return true
    end

    # checking whether last lanelet of actor1.route merges with any lanelet of actor2.route 
    @inbounds for merg in scenario.ln.lanelets[actor1.route.route[end]].merging_with
        in(merg, actor2.route.route) && return true
    end

    # if both is not the case, the routes do not merge
    return false
end

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

@inline function safety_distance(state1::StateCurv, state2::StateCurv)
    return max(10.0, state1.lon.v, state2.lon.v) # safety distance in meters
end

function is_valid(rel::Relation{IsOnSameLaneSection}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    ltid1 = LaneletID(actor1, state1, scenario.ln)
    ltid2 = LaneletID(actor2, state2, scenario.ln)

    # same lanelet?
    ltid1 == ltid2 && return true

    # iterate to right
    lt = ltid1
    while scenario.ln.lanelets[lt].adjRght.is_exist
        lt = scenario.ln.lanelets[lt].adjRght.lanlet_id
        lt == ltid2 && return true
    end

    # iterate to left
    lt = ltid1
    while scenario.ln.lanelets[lt].adjLeft.is_exist
        lt = scenario.ln.lanelets[lt].adjLeft.lanelet_id
        lt == ltid2 && return true
    end

    return false
end

is_valid(rel::Relation{IsFaster}, scenario::Scenario, state1::StateCurv, state2::StateCurv) = state1.lon.v > state2.lon.v # TODO remove unnecessary arguments? 

function is_valid(rel::Relation{IsBeforeConflictingArea}, scenario::Scenario, state::StateCurv)
    
end