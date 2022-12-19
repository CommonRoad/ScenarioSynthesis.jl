using JuMP
using Gurobi

const MyType = Float64

function sqFree(x)
    str = "String" 
    b = 2.0
    return x^2 + b 
end

model = Model(Gurobi.Optimizer)
@variable(model, x[1:5], Bin)
@variable(model, y[1:5])
@objective(model, Max, sum(x))
for i=1:5
    @constraint(model, y[i] == sqFree(x[i]))
end
optimize!(model)

value.(model.obj_dict[:x])
value(model.obj_dict[:x][1])