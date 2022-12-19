import JuMP.VariableRef, JuMP.value

binary(rel::Relation{IsOnLanelet}, scenario::Scenario, state::VariableRef) = binary(rel, scenario, StateCurv(value(state), 0.0, 0.0, 0.0, 0.0, 0.0))

function binary(rel::Relation{IsOnLanelet}, scenario::Scenario, state::StateCurv)
    actor = scenario.actors.actors[rel.actor1]

    ltid = LaneletID(actor, state, scenario.ln)

    return rel.lanelet == ltid
end

function binary(rel::Relation{IsOnSameLaneSection}, scenario::Scenario, state1::StateCurv, state2::StateCurv)
    actor1 = scenario.actors.actors[rel.actor1]
    actor2 = scenario.actors.actors[rel.actor2]

    ltid1 = LaneletID(actor1, state1, scenario.ln)
    ltid2 = LaneletID(actor2, state2, scenario.ln)

    # same lanelet?
    ltid1 == ltid2 && return true

    # iterate to right
    lt = ltid1
    while scenario.ln.lanelets[lt].adjRght.is_exist && scenario.ln.lanelets[lt].adjRght.is_same_direction
        lt = scenario.ln.lanelets[lt].adjRght.lanlet_id
        lt == ltid2 && return true
    end

    # iterate to left
    lt = ltid1
    while scenario.ln.lanelets[lt].adjLeft.is_exist && scenario.ln.lanelets[lt].adjLeft.is_same_direction
        lt = scenario.ln.lanelets[lt].adjLeft.lanelet_id
        lt == ltid2 && return true
    end

    return false
end