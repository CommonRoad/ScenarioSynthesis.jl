import JuMP.Model, JuMP.set_attribute, JuMP.@variable, JuMP.@objective, JuMP.@constraint
import Gurobi

function synthesize_optimization_problem(agent::Agent, Δt::Real, grb_env::Gurobi.Env)
    model = Model(() -> Gurobi.Optimizer(grb_env); add_bridges=false)
    set_attribute(model, "output_flag", false)
    N = length(agent.states)

    @variable(model, state[1:N, 1:3])
    @objective(model, Min, sum(state[:, 3].^2))

    for i=1:N-1 # dynamic limits -- TODO add constraints for vel and acc also necessary?
        @constraint(model, state[i+1, 1] == state[i, 1] + state[i, 2] * Δt + state[i, 3] / 2 * Δt^2)
        @constraint(model, state[i+1, 2] == state[i, 2] + state[i, 3] * Δt)
    end

    for i=1:N
        agent.states[i].is_empty && throw(error("cannot synthesize trajectory for empty set: $i"))
        prev_vert = agent.states[i].vertices[end]
        for vert in agent.states[i].vertices
            ref_vec = rotate_ccw90(vert - prev_vert)

            @constraint(model, (state[i, 1] - prev_vert[1]) * ref_vec[1] + (state[i, 2] - prev_vert[2]) * ref_vec[2] >= 0)
            prev_vert = vert
        end
    end

    return model
end