import JuMP.Model, JuMP.optimize!, JuMP.set_optimizer_attribute

function solve_optimization_problem!(model::Model)
    # TODO tune parameters? 
    # set_optimizer_attribute(model, "NonConvex", 2)
    return optimize!(model)
end