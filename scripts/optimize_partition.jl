using Gurobi
using JuMP

function optimize_partition(
    lower_bounds::Vector{T},
    upper_bounds::Vector{T},
    grb_env::Gurobi.Env
) where {T<:Real}
    @assert length(lower_bounds) == length(upper_bounds)
    N = length(lower_bounds)

    model = Model(() -> Gurobi.Optimizer(grb_env); add_bridges=false)
    # set_optimizer_attribute(model, "NonConvex", 2)
    @variable(model, lower[1:N])
    @variable(model, upper[1:N])
    @variable(model, root[1:N])
    @objective(model, Max, sum(upper-lower))

    for i=1:N
        @constraint(model, lower_bounds[i] ≤ lower[i])
        @constraint(model, upper[i] ≤ upper_bounds[i])
        @constraint(model, lower[i] ≤ upper[i])
    end
    for i=1:N-1
        @constraint(model, upper[i] ≤ lower[i+1])
    end

    optimize!(model)

    return value.(lower), value.(upper)
end

lower = [1.0, 1.0, 1.0]
upper = [8.0, 8.0, 8.0]
grb_env = Gurobi.Env()

optimize_partition(lower, upper, grb_env)