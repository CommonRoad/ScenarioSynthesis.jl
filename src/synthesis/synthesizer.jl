import JuMP.Model, JuMP.@variable, JuMP.@constraint, JuMP.@objective, JuMP.optimize!, JuMP.value, JuMP.VariableRef
import JuMP
import Gurobi
import Plots.plot 
import StaticArrays.SMatrix, StaticArrays.SVector

const Jerk = Float64

function next_state(state::StateLon, jerk::Jerk, Δt::Number)
    state = SVector{3, Float64}(state)
    system = SMatrix{3, 3, Float64, 9}(1, 0, 0, Δt, 1, 0, 1/2*Δt^2, Δt, 1)
    excitation = SVector{3, Float64}(1/6*Δt^3, 1/2*Δt^2, Δt)

    return system * state + excitation * jerk
end

# synthesize longitudinal optimization problem
function synthesize_optimization_problem(scenario::Scenario, Δt::Number=0.2)
    model = Model(Gurobi.Optimizer)
    duration_max = sum([scene.δ_max for (scene_id, scene) in scenario.scenes.scenes])
    N = floor(Int64, duration_max/Δt)
    n_actors = length(scenario.actors.actors)
    n_scenes = length(scenario.scenes.scenes)
    
    ### set up variables 
    @variable(model, jerk[1:N, 1:n_actors])
    @variable(model, state[1:N+1, 1:n_actors, 1:3])
    @variable(model, scene_seen[1:N+1, 1:n_scenes+1], Bin)
    @variable(model, scene_active[1:N+1, 1:n_scenes], Bin)
    @variable(model, default_true, Bin)
    
    ### set up objective function 
    @objective(model, Min, sum(jerk.^2)) # use acc instead?
    
    ### set up constraints
    # store lims -- TODO dicts instead of vectors?
    s_low_lims = zeros(Float64, 5)
    s_upp_lims = [actor.route.frame.cum_dst[end] for (k, actor) in scenario.actors.actors]
    v_low_lims = [actor.v_min for (k, actor) in scenario.actors.actors]
    v_upp_lims = [actor.v_max for (k, actor) in scenario.actors.actors]
    a_low_lims = [actor.a_min for (k, actor) in scenario.actors.actors]
    a_upp_lims = [actor.a_max for (k, actor) in scenario.actors.actors]
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
    #@constraint(model, state[1, 1, :] .== [3.0, 0.0, 0.0])
    #@constraint(model, state[201, 1, :] .== [110.0, 1.0, 0.0])

    # static and dynamic limits of vehicle
    for i=1:N+1
        for j=1:n_actors
            @constraint(model, s_low_lims[j] ≤ state[i,j,1] ≤ s_upp_lims[j]) # TODO should be handeled by other constraints
            @constraint(model, v_low_lims[j] ≤ state[i,j,2] ≤ v_upp_lims[j])
            @constraint(model, a_low_lims[j] ≤ state[i,j,3] ≤ a_upp_lims[j])
        end
    end

    # order and switching times of scenes
    @constraint(model, scene_seen[1,:] .== [true, zeros(Bool, n_scenes)...]) # first scene active

    for i=1:N
        for j=1:n_scenes
            @constraint(model, scene_seen[i+1,j] ≥ scene_seen[i,j]) # once a scene has been seen, it cannot be undone
            @constraint(model, scene_seen[i+1,j+1] ≤ scene_seen[i+1,j]) # a scene can only be activate, if the previous scene has also been seen 
        end
    end

    for i=1:N+1
        for j=1:n_scenes
            @constraint(model, scene_active[i,j] == (scene_seen[i,j] - scene_seen[i,j+1])) # calculate active scene
        end
    end

    for j=1:n_scenes
        @constraint(model, n_low_lims[j] ≤ sum(scene_active[:,j]) ≤ n_upp_lims[j]) # keep scene durations within limits
    end

    # constraints from predicates
    for (scene_id, scene) in scenario.scenes.scenes
        for rel in scene.relations
            # add_constraint!(model, rel, scene_id, scenario)
            #if typeof(rel) == Relation{IsOnLanelet}

            #end
        end
    end
    return model
end