import Gurobi.Env
import Base.Threads.@threads

function benchmark(
    n_iter::Integer,
    specvec::Vector{<:Vector{<:Predicate}},
    k_max::Integer,
    Δt::Real,
    agents_input::AgentsDict,
    grb_env::Env, 
    ψ::Real=0.5; 
    synthesize_trajectories::Bool=true
)
    A = SMatrix{2, 2, Float64, 4}(0, 0, 1, 0)
    agents = deepcopy(agents_input)
    for j=1:n_iter
        for (agent_id, agent) in agents_input.agents
            empty!(agents.agents[agent_id].states)
            push!(agents.agents[agent_id].states, agent.states[1])
        end

        # forward propagation
        for i=1:k_max
            # restrict convex set to match specifications
            for pred in specvec[i]
                apply_predicate!(pred, agents, i, ψ)
            end

            # propagate convex set to get next time step
            for (agent_id, agent) in agents.agents
                @assert length(agent.states) == i 
                prop = propagate(agent.states[i], A, agent.a_ub, agent.a_lb, Δt)
                push!(agent.states, prop)
            end
        end

        # backward propagation
        for (agent_id, agent) in agents.agents
            for i in reverse(1:k_max-1)
                backward = propagate_backward(agent.states[i+1], A, agent.a_ub, agent.a_lb, Δt)
                intersect = ScenarioSynthesis.intersection(agent.states[i], backward) 
                agent.states[i] = intersect
            end
        end

        if synthesize_trajectories
            traj_reach = Dict{AgentID, Trajectory}()
            @threads for i in 1:length(agents.agents)
                agent_id = i
                agent = agents.agents[i]
                optim = synthesize_optimization_problem(agent, Δt, grb_env)
                optimize!(optim)
                traj_reach[agent_id] = Trajectory(Vector{State}(undef, length(agent.states)))
                counter = 0 
                for val in eachrow(JuMP.value.(optim.obj_dict[:state][:,1:2]))
                    counter += 1
                    traj_reach[agent_id][counter] = State(val[1], val[2])
                end
            end
        end
    end

    return nothing
end