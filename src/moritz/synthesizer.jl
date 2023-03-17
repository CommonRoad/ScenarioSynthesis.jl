import JuMP.Model, JuMP.@variable, JuMP.@constraint, JuMP.@objective, JuMP.optimize!, JuMP.value, JuMP.VariableRef
import JuMP
import Gurobi
import Plots.plot 
import StaticArrays.SMatrix, StaticArrays.SVector

const Jerk = Float64
const bigM = 1e6 # TODO Inf64?

# synthesize longitudinal optimization problem
function synthesize_optimization_problem(scenario::Scenario, Δt::Number)
    model = Model(Gurobi.Optimizer)
    duration_max = sum([scene.δ_max for (scene_id, scene) in scenario.scenes.scenes])
    N = floor(Int64, duration_max/Δt)
    n_actors = length(scenario.actors.actors)
    n_scenes = length(scenario.scenes.scenes)
    n_conlict_sections = sum([length(actor.route.conflict_sections) for (actor_id, actor) in scenario.actors.actors])
    
    ### set up variables 
    @variable(model, jerk[1:N, 1:n_actors])
    @variable(model, state[1:N+1, 1:n_actors, 1:3])
    @variable(model, scene_seen[1:N+1, 1:n_scenes+1], Bin)
    @variable(model, scene_active[1:N+1, 1:n_scenes], Bin)
    @variable(model, in_cs[1:N+1, 1:n_conlict_sections], Bin)
    @variable(model, cost_var[1:N, 1:n_actors])

    
    for i=1:N
        @constraint(model, cost_var[i,:] .== jerk[i,:] .* (1 - scene_seen[i, n_scenes+1]))
    end
  
    ### set up objective function 
    @objective(model, Min, sum(cost_var.^2)) # use acc instead?
    

    # @objective(model, Min, sum(jerk.^2))

    ### set up constraints
    # store lims -- TODO dicts instead of vectors?
    s_low_lims = zeros(Float64, 5)
    s_upp_lims = [actor.route.frame.cum_dst[end] for (k, actor) in scenario.actors.actors]
    v_low_lims = [actor.v_lb for (k, actor) in scenario.actors.actors]
    v_upp_lims = [actor.v_ub for (k, actor) in scenario.actors.actors]
    a_low_lims = [actor.a_lb for (k, actor) in scenario.actors.actors]
    a_upp_lims = [actor.a_ub for (k, actor) in scenario.actors.actors]
    n_low_lims = [ceil(Int64, scene.δ_min / Δt) for (k, scene) in scenario.scenes.scenes]
    n_upp_lims = [floor(Int64, scene.δ_max / Δt) for (k, scene) in scenario.scenes.scenes]

    # vehicle model
    for i=1:N
        for j=1:n_actors
            @constraint(model, state[i+1,j,1] == state[i,j,1] + state[i,j,2] * Δt + state[i,j,3] * Δt^2 / 2 + jerk[i,j] * Δt^3 / 6)
            @constraint(model, state[i+1,j,2] == state[i,j,2] + state[i,j,3] * Δt + jerk[i,j] * Δt^2 / 2)
            @constraint(model, state[i+1,j,3] == state[i,j,3] + jerk[i,j] * Δt)
        end
    end

    # static and dynamic limits of vehicle
    for i=1:N+1
        for j=1:n_actors
            @constraint(model, s_low_lims[j] ≤ state[i,j,1] ≤ s_upp_lims[j]) # TODO should be handeled by other constraints?
            @constraint(model, v_low_lims[j] ≤ state[i,j,2] ≤ v_upp_lims[j])
            @constraint(model, a_low_lims[j] ≤ state[i,j,3] ≤ a_upp_lims[j])
        end
    end

    # order and switching times of scenes
    @constraint(model, scene_seen[1,:] .== [true, zeros(Bool, n_scenes)...]) # first scene active

    for i=1:N
        for j=1:n_scenes+1
            @constraint(model, scene_seen[i+1,j] ≥ scene_seen[i,j]) # once a scene has been seen, it cannot be undone
        end
        for j=1:n_scenes
            @constraint(model, scene_seen[i+1,j+1] ≤ scene_seen[i+1,j]) # a scene can only be activate, if the previous scene has also been seen 
        end
    end

    for i=1:N+1
        for j=1:n_scenes
            @constraint(model, scene_active[i,j] == (scene_seen[i,j] - scene_seen[i,j+1])) # determine active scene
        end
    end

    for j=1:n_scenes
        @constraint(model, n_low_lims[j] ≤ sum(scene_active[:,j]) ≤ n_upp_lims[j]) # keep scene durations within limits
    end

    # use inital convex sets as "hint" / constraint
    for (actor_id, actor) in scenario.actors.actors
        @constraint(model, min(actor.states[1], 1) ≤ state[1, actor_id, 1])
        @constraint(model, state[1, actor_id, 1] ≤ max(actor.states[1], 1))
        @constraint(model, min(actor.states[1], 2) ≤ state[1, actor_id, 2])
        @constraint(model, state[1, actor_id, 2] ≤ max(actor.states[1], 2))
    end


    # constraints from predicates (scene specific)
    for (scene_id, scene) in scenario.scenes.scenes
        for pred in scene.relations
            if typeof(pred) == OnLanelet
                lb, ub, _ = scenario.actors.actors[pred.actor_ego].route.lanelet_interval[first(pred.lanelet)] # TODO using first from set causes problems if there are more than one lanelets in the set. -- upgrade!
                # @info pred, lb, ub
                for i=1:N
                    @constraint(model, lb - bigM * (1 - scene_active[i, scene_id]) ≤ state[i, pred.actor_ego, 1])
                    @constraint(model, state[i, pred.actor_ego, 1] ≤ ub + bigM * (1 - scene_active[i, scene_id]))
                end
            end
        end
    end

    return model
end
