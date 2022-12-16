import JuMP.Model, JuMP.@constraint

function add_constraint!(model::Model, rel::Relation{IsOnLanelet}, scenario::Scenario)
    actor = scenario.actors.actors[rel.actor1]
    ind = findfirst(x -> x == rel.lanelet, actor.route)
    i, j = 2, 2
    return @constraint(model, actor.route.transition_points[ind] ≤ state[i,j,1] ≤ actor.route0.transition_points[ind+1])
end