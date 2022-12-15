import JuMP.Model, JuMP.@variable, JuMP.@constraint, JuMP.@objective, JuMP.optimize!, JuMP.value
import Gurobi
import Plots.plot 

function synthesize_milp()
    model = Model(Gurobi.Optimizer)
    N = 100
    Δt = 0.1
    avg_acc = 2.4
    @variable(model, a[1:N])
    @variable(model, v[1:N+1])
    @variable(model, s[1:N+1])
    @objective(model, Min, sum(a.^2))

    @constraint(model, s[1] == 0.0)
    @constraint(model, s[N+1] == 0.5*avg_acc*(N*Δt)^2)
    @constraint(model, v[1] == 0.0)
    @constraint(model, v[N+1] == avg_acc*(N*Δt))

    for i=1:N
        @constraint(model, s[i+1] == s[i] + v[i] * Δt + 0.5 * a[i] * Δt^2)
        @constraint(model, v[i+1] == v[i] + a[i] * Δt)
    end

    optimize!(model)
    p = plot([value.(s), value.(v), value.(a)];label=["dst" "vel" "acc"])
    return p
end