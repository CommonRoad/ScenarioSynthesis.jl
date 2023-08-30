import JuMP.Model, JuMP.@variable, JuMP.@constraint, JuMP.@objective, JuMP.optimize!, JuMP.value, JuMP.VariableRef
import JuMP
import Gurobi
import Plots.plot 
import StaticArrays.SMatrix, StaticArrays.SVector

const Jerk = Float64
const bigM = 1e6 # TODO Inf64?

# synthesize longitudinal optimization problem
function synthesize_optimization_problem(scenario::Scenario, Δt::Number; position_limit::Bool=false)
    safety_margin = 10.0
    @info "keeping a safety margin of $(safety_margin)m between agents."
    model = Model(Gurobi.Optimizer)
    duration_max = sum([scene.δ_max for (scene_id, scene) in scenario.scenes.scenes])
    N = floor(Int64, duration_max/Δt)
    n_agents = length(scenario.agents.agents)
    n_scenes = length(scenario.scenes.scenes)
    n_conlict_sections = sum([length(agent.route.conflict_sections) for (agent_id, agent) in scenario.agents.agents])
    
    ### set up variables 
    @variable(model, jerk[1:N, 1:n_agents])
    @variable(model, state[1:N+1, 1:n_agents, 1:3])
    @variable(model, scene_seen[1:N+1, 1:n_scenes+1], Bin)
    @variable(model, scene_active[1:N+1, 1:n_scenes], Bin)
    @variable(model, in_cs[1:N+1, 1:n_conlict_sections], Bin)
    @variable(model, cost_var[1:N, 1:n_agents])

    
    #for i=1:N
    #    @constraint(model, cost_var[i,:] .== jerk[i,:] .* (1 - scene_seen[i, n_scenes+1]))
    #end
  
    for i=1:N
        @constraint(model, cost_var[i,:] .== state[i,:,3] .* (1 - scene_seen[i, n_scenes+1]))
    end

    ### set up objective function 
    @objective(model, Min, sum(cost_var.^2)) # use acc instead?
    

    # @objective(model, Min, sum(jerk.^2))

    ### set up constraints
    # vehicle model
    for i=1:N
        for j=1:n_agents
            @constraint(model, state[i+1,j,1] == state[i,j,1] + state[i,j,2] * Δt + state[i,j,3] * Δt^2 / 2 + jerk[i,j] * Δt^3 / 6)
            @constraint(model, state[i+1,j,2] == state[i,j,2] + state[i,j,3] * Δt + jerk[i,j] * Δt^2 / 2)
            @constraint(model, state[i+1,j,3] == state[i,j,3] + jerk[i,j] * Δt)
        end
    end

    # static and dynamic limits of vehicle
    for i=1:N+1
        for j=1:n_agents
            position_limit && @constraint(model, 0.0 ≤ state[i,j,1] ≤ scenario.agents.agents[j].route.frame.cum_dst[end])
            @constraint(model, scenario.agents.agents[j].v_lb ≤ state[i,j,2] ≤ scenario.agents.agents[j].v_ub)
            @constraint(model, scenario.agents.agents[j].a_lb ≤ state[i,j,3] ≤ scenario.agents.agents[j].a_ub)
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
        @constraint(model, ceil(Int64, scenario.scenes.scenes[j].δ_min / Δt) ≤ sum(scene_active[:,j]) ≤ floor(Int64, scenario.scenes.scenes[j].δ_max / Δt)) # keep scene durations within limits
    end

    if true
        # use inital convex sets as "hint" / constraint
        for (agent_id, agent) in scenario.agents.agents
            @constraint(model, min(agent.states[1], 1) ≤ state[1, agent_id, 1])
            @constraint(model, state[1, agent_id, 1] ≤ max(agent.states[1], 1))
            @constraint(model, min(agent.states[1], 2) ≤ state[1, agent_id, 2])
            @constraint(model, state[1, agent_id, 2] ≤ max(agent.states[1], 2))
        end
    else
        @warn "initial conves set as constraint deactivated."
    end

    # constraints from predicates (scene specific)
    for (scene_id, scene) in scenario.scenes.scenes
        for pred in scene.relations
            if typeof(pred) == OnLanelet
                lb, ub, _ = scenario.agents.agents[pred.agent_ego].route.lanelet_interval[first(pred.lanelet)] # TODO using first from set causes problems if there are more than one lanelets in the set. -- upgrade!
                # @info pred, lb, ub
                for i=1:N
                    @constraint(model, lb - bigM * (1 - scene_active[i, scene_id]) ≤ state[i, pred.agent_ego, 1])
                    @constraint(model, state[i, pred.agent_ego, 1] ≤ ub + bigM * (1 - scene_active[i, scene_id]))
                end
            
            elseif typeof(pred) == BehindAgent
                @assert length(pred.agents) == 2 # more complex predicates can be split into multiple easier ones.
                for i=1:N
                    @constraint(model, state[i, pred.agents[1], 1] + scenario.agents.agents[pred.agents[1]].lenwid[1] / 2 + scenario.agents.offset[pred.agents[1], pred.agents[2]] + safety_margin ≤ state[i, pred.agents[2], 1] - scenario.agents.agents[pred.agents[2]].lenwid[1] / 2 + bigM * (1 - scene_active[i, scene_id]))
                end

            elseif typeof(pred) == SlowerAgent
                @assert length(pred.agents) == 2 # more complex predicates can be split into multiple easier ones.
                for i=1:N
                    @constraint(model, state[i, pred.agents[1], 2] ≤ state[i, pred.agents[2], 2] + bigM * (1 - scene_active[i, scene_id]))
                end

            elseif typeof(pred) == BeforeConflictSection
                for i=1:N
                    @constraint(model, state[i, pred.agent_ego, 1] + scenario.agents.agents[pred.agent_ego].lenwid[1] / 2 ≤ scenario.agents.agents[pred.agent_ego].route.conflict_sections[pred.conflict_section][1] + bigM * (1 - scene_active[i, scene_id]))
                end

            elseif typeof(pred) == BehindConflictSection
                for i=1:N
                    @constraint(model, scenario.agents.agents[pred.agent_ego].route.conflict_sections[pred.conflict_section][2] - bigM * (1 - scene_active[i, scene_id]) ≤ state[i, pred.agent_ego, 1] - scenario.agents.agents[pred.agent_ego].lenwid[1] / 2)
                end

            elseif typeof(pred) == OnConflictSection
                for i=1:N
                    @constraint(model, scenario.agents.agents[pred.agent_ego].route.conflict_sections[pred.conflict_section][1] - scenario.agents.agents[pred.agent_ego].lenwid[1] / 2 - bigM * (1 - scene_active[i, scene_id]) ≤ state[i, pred.agent_ego, 1])
                    @constraint(model, state[i, pred.agent_ego, 1] ≤ scenario.agents.agents[pred.agent_ego].route.conflict_sections[pred.conflict_section][2] + scenario.agents.agents[pred.agent_ego].lenwid[1] / 2 + bigM * (1 - scene_active[i, scene_id]))
                end

            else
                @warn "type $(typeof(pred)) not supported yet."
            end
        end
    end

    return model
end
