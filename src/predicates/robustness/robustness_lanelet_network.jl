function robustness(rel::Relation{IsOnLanelet}, scenario::Scenario, state::StateCurv)
    actor = scenario.actors.actors[rel.actor1]

    ltid = LaneletID(actor, state, scenario.ln)
    if rel.lanelet == ltid
        rtid = findfirst(x -> x == ltid, actor.route.route)
        s_lt = state.lon.s - actor.route.transition_points[rtid]
        s_lt_rel = s_lt / scenario.ln.lanelets[ltid].frame.cum_dst[end]
        d_rght, d_left = lanelet_thickness(scenario.ln.lanelets[ltid], s_lt)
        d_lt_rel = (state.lat.d - d_rght) / (d_left - d_rght)
        return 0.5 - (s_lt_rel - 0.5)^2 - (d_lt_rel - 0.5)^2
    else
        distance_to = 20.0 # TODO implement correct version 
        return -distance_to
    end
end

function robustness(rel::Relation{IsOnSameLaneSection}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    ltid1 = LaneletID(actor1, state1, scenario.ln)
    ltid2 = LaneletID(actor2, state2, scenario.ln)

    # same lanelet?
    ltid1 == ltid2 && return 100.0 # TODO think of correct implementation

    # iterate to right
    lt = ltid1
    while scenario.ln.lanelets[lt].adjRght.is_exist && scenario.ln.lanelets[lt].adjRght.is_same_direction
        lt = scenario.ln.lanelets[lt].adjRght.lanlet_id
        lt == ltid2 && return 100.0
    end

    # iterate to left
    lt = ltid1
    while scenario.ln.lanelets[lt].adjLeft.is_exist && scenario.ln.lanelets[lt].adjLeft.is_same_direction
        lt = scenario.ln.lanelets[lt].adjLeft.lanelet_id
        lt == ltid2 && return 100.0
    end

    return -100.0
end

function robustness(rel::Relation{IsOnLanelet}, scenario::Scenario, lon)
    route = scenario.actors.actors[rel.actor1].route
    id = findfirst(x -> x == rel.lanelet, route.route)
    typeof(id) == Nothing && throw(error("lanelet id not part of route.")) # TODO catch when creating the relation!!
    start = route.transition_points[id]
    finish = route.transition_points[id+1]

    return (lon - start) * (finish - lon) # min(abs(start-lon), abs(finish-lon))
end