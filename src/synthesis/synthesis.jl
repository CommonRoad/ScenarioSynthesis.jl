import DataStructures.PriorityQueue, DataStructures.enqueue!, DataStructures.dequeue_pair!
import Base.Iterators.product
import Memoize.@memoize

const CostType = Float64

struct SearchState
    k::TimeStep
    identifier::Int64
end

const Trajectory = Vector{State}

@memoize function sampling_states(cs::ConvexSet, n_pos::Integer, n_vel::Integer)
    itr_pos = range(min(cs, 1), max(cs, 1), n_pos)
    itr_vel = range(min(cs, 2), max(cs, 2), n_vel)
    return product(itr_pos, itr_vel) 
end

function synthesize_trajectories(actors::ActorsDict, k_max::Integer, Δt::Real; relax::Real=1.0)
    trajectories = Dict{ActorID, Trajectory}()
    for (actor_id, actor) in actors.actors
        @assert length(actor.states) ≥ k_max # TODO == ? required to be backwards propagated? 

        # inits
        state_dict = Dict{SearchState, State}()
        prev_state_dict = Dict{SearchState, SearchState}()
        cost_dict = Dict{SearchState, CostType}()
        queue = PriorityQueue{SearchState, CostType}()

        # initial state
        counter = 0
        for (pos, vel) in sampling_states(actor.states[1], 10, 10)
            counter += 1
            temp_state = State(pos, vel)
            if is_within(temp_state, actor.states[1])
                state_dict[SearchState(1, counter)] = temp_state
                queue[SearchState(1, counter)] = 0.0
            end
        end

        # graph search
        prev_state_ref = SearchState(0, 0)
        trajectory_found = false
        while !isempty(queue)
            prev_state, prev_cost = dequeue_pair!(queue)
            # @info prev_state

            if prev_state.k ≥ k_max
                prev_state_ref = prev_state
                trajectory_found = true
                break
            end

            counter = 0
            for (pos, vel) in sampling_states(actor.states[prev_state.k+1], 20, 20)
                counter += 1
                temp_state = State(pos, vel)
                if is_within(temp_state, actor.states[prev_state.k+1])
                    a_vel = (temp_state.vel - state_dict[prev_state].vel) / Δt
                    a_pos = (temp_state.pos - state_dict[prev_state].pos - state_dict[prev_state].vel * Δt) * 2 / Δt^2
                    # isapprox(a_vel, a_pos; atol=1e-2, rtol=1e-2) || @warn "a_vel: $a_vel, a_pos: $a_pos"
                    if (actor.a_lb ≤ a_vel/relax ≤ actor.a_ub) && (actor.a_lb ≤ a_pos/relax ≤ actor.a_ub)
                        a_max_sq = max(a_vel^2, a_pos^2)
                        add_cost = a_max_sq # a_max_sq # + 2.0 * max(0.0, (20.0-vel)^2) 
                        add_cost = max(add_cost, 0.0)
                        temp_cost = prev_cost + add_cost
                        temp_cost = max(temp_cost, 0.0)
                        search_state = SearchState(prev_state.k+1, counter)
                        if !haskey(cost_dict, search_state) || temp_cost < cost_dict[search_state]
                            state_dict[search_state] = temp_state
                            prev_state_dict[search_state] = prev_state
                            cost_dict[search_state] = temp_cost
                            queue[search_state] = temp_cost
                        end
                    end
                end
            end
        end

        # reconstruct trajectory
        trajectory_found || throw(error("no trajectory found for actor $actor_id."))

        prev_state = prev_state_ref
        trajectories[actor_id] = [state_dict[prev_state]]
        while prev_state.k ≥ 2
            prev_state = prev_state_dict[prev_state]
            pushfirst!(trajectories[actor_id], state_dict[prev_state])
        end
    end
    return trajectories
end