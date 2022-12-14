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