import Gurobi: Env, Optimizer
import JuMP: Model, @variable, @objective, @constraint, optimize!, value, set_silent

function optimize_partition(
    lower_bounds::Vector{T},
    upper_bounds::Vector{T},
    grb_env::Env
) where {T<:Real}
    @assert length(lower_bounds) == length(upper_bounds)
    N = length(lower_bounds)

    # any((upper_bounds - lower_bounds) .< 0) && throw(error("non feasible"))
    ref_value = sum(upper_bounds - lower_bounds)

    model = Model(() -> Optimizer(grb_env); add_bridges=false)
    set_silent(model)
    # set_optimizer_attribute(model, "NonConvex", 2)
    @variable(model, lower[1:N])
    @variable(model, upper[1:N])
    @variable(model, root[1:N])
    @objective(model, Min, sum((upper.-lower.-ref_value).^2))

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