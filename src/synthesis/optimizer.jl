import JuMP.Model, JuMP.optimize!

function solve_optimization_problem(model::Model)
    # TODO tune parameters? 
    return optimize!(model)
end