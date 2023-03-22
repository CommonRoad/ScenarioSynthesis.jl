import Gurobi.Env
import StaticArrays.SMatrix
import Base.Threads.@threads

function benchmark(
    n_iter::Integer,
    spec::Vector{Set{Predicate}},
    k_max::Integer,
    Δt::Real,
    actors_input::ActorsDict,
    grb_env::Env, 
    ψ::Real=0.5; 
    synthesize_trajectories::Bool=true
)
    A = SMatrix{2, 2, Float64, 4}(0, 0, 1, 0)
    for j=1:n_iter
        actors = deepcopy(actors_input)

        # forward propagation
        for i=1:k_max
            # restrict convex set to match specifications
            for pred in sort([spec[i]...], lt=type_ranking)
                apply_predicate!(pred, actors, i, ψ)
            end

            # propagate convex set to get next time step
            for (actor_id, actor) in actors.actors
                @assert length(actor.states) == i 
                prop = propagate(actor.states[i], A, actor.a_ub, actor.a_lb, Δt)
                push!(actor.states, prop)
            end
        end

        # backward propagation
        for (actor_id, actor) in actors.actors
            for i in reverse(1:k_max-1)
                backward = propagate_backward(actor.states[i+1], A, actor.a_ub, actor.a_lb, Δt)
                intersect = ScenarioSynthesis.intersection(actor.states[i], backward) 
                actor.states[i] = intersect
            end
        end

        if synthesize_trajectories
            traj_reach = Dict{ActorID, Trajectory}()
            @threads for i in 1:length(actors.actors)
                actor_id = i
                actor = actors.actors[i]
                optim = synthesize_optimization_problem(actor, Δt, grb_env)
                optimize!(optim)
                traj_reach[actor_id] = Trajectory(Vector{State}(undef, length(actor.states)))
                counter = 0 
                for val in eachrow(JuMP.value.(optim.obj_dict[:state][:,1:2]))
                    counter += 1
                    traj_reach[actor_id][counter] = State(val[1], val[2])
                end
            end
        end
    end

    return nothing
end