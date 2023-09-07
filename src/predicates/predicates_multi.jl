abstract type PredicateMulti <: BasicPredicate end

struct SlowerAgent <: PredicateMulti
    agents::Vector{AgentID}
    function SlowerAgent(agents::AbstractVector{AgentID})
        @assert length(agents) ≥ 2
        return new(agents)
    end
end

function apply_predicate!(
    predicate::SlowerAgent,
    agents::AgentsDict,
    k::TimeStep,
    env::Union{Env, Nothing}=nothing,
    unnecessary...
)
    if isnothing(env)
        max_prev = max(agents.agents[predicate.agents[1]].states[k], 2)
        min_prev = min(agents.agents[predicate.agents[1]].states[k], 2)
        
        for i in 1:length(predicate.agents)-1
            max_this = max(agents.agents[predicate.agents[i+1]].states[k], 2)
            min_this = min(agents.agents[predicate.agents[i+1]].states[k], 2)

            min_this = max(min_prev, min_this)
            max_prev = min(max_prev, max_this)

            @info min_prev, max_prev, min_this, max_this
            if min_this < max_prev
                ϕ = i / length(predicate.agents)
                threshold = ϕ * max_prev + (1-ϕ) * min_this
            
                bounds_prev = Bounds(-Inf, Inf, -Inf, threshold)    
                bounds_this = Bounds(-Inf, Inf, threshold, Inf)  

                apply_bounds!(agents.agents[predicate.agents[i]].states[k], bounds_prev)
                apply_bounds!(agents.agents[predicate.agents[i+1]].states[k], bounds_this)

                min_prev = threshold
                max_prev = max_this
            else
                min_prev = min_this
                max_prev = max_this
            end
        end
    else # optimization based
        M = length(predicate.agents)
        v_min = Vector{Float64}(undef, M)
        v_max = Vector{Float64}(undef, M)

        @inbounds for i=1:M
            agent = agents.agents[predicate.agents[i]]
            v_min[i], v_max[i] = v(agent.states[k])
        end

        v_min_opt, v_max_opt = optimize_partition(v_min, v_max, env)

        for i=1:M
            agent = agents.agents[predicate.agents[i]]
            if v_min_opt[i] > v_min[i] + 1e-3
                limit!(agent.states[k], Limit(State(0, v_min_opt[i]), SVector{2, Float64}(0, 1)))
            end
            if v_max_opt[i] < v_max_opt[i] - 1e-3
                limit!(agent.states[k], Limit(State(0, v_max_opt[i]), SVector{2, Float64}(0, -1)))
            end
        end
    end
    
    return nothing
end

function v(cs::ConvexSet)
    v_min = Inf64
    v_max = -Inf64

    @inbounds for v in cs.vertices
        v[2] < v_min ? v_min = v[2] : nothing
        v[2] > v_max ? v_max = v[2] : nothing
    end
    
    return v_min, v_max
end

struct BehindAgent <: PredicateMulti 
    agents::Vector{AgentID}

    function BehindAgent(agents::AbstractVector{AgentID})
        @assert length(agents) ≥ 2
        return new(agents)        
    end
end

function apply_predicate!(
    predicate::BehindAgent,
    agents::AgentsDict,
    k::TimeStep,
    grb_env::Union{Env, Nothing}=nothing,
    unnecessary...
)
    offsets = [agents.offset[predicate.agents[i], predicate.agents[i+1]] for i=1:length(predicate.agents)-1] # TODO check sign!
    cumsum!(offsets, offsets)
    pushfirst!(offsets, 0.0)

    max_prev = max(agents.agents[predicate.agents[1]].states[k], 1) # offset 0 for first vehicle
    min_prev = min(agents.agents[predicate.agents[1]].states[k], 1)

    if isnothing(grb_env)# TODO consider length of agents before mediation?
        for i in 1:length(predicate.agents)-1
            max_this = max(agents.agents[predicate.agents[i+1]].states[k], 1) - offsets[i+1] 
            min_this = min(agents.agents[predicate.agents[i+1]].states[k], 1) - offsets[i+1] 

            min_this = max(min_prev, min_this)
            max_prev = min(max_prev, max_this)

            # @info min_prev, max_prev, min_this, max_this
            if min_this + agents.agents[predicate.agents[i]].lenwid[1] / 2 < max_prev - agents.agents[predicate.agents[i+1]].lenwid[1] / 2
                ϕ = i / length(predicate.agents)
                # TODO one should consider the length of the agents -- matters if agents' length substantially differs
                threshold = ϕ * (max_prev - agents.agents[predicate.agents[i+1]].lenwid[1] / 2) + (1-ϕ) * (min_this + agents.agents[predicate.agents[i]].lenwid[1] / 2)
                # @info threshold
            
                bounds_prev = Bounds(-Inf, threshold + offsets[i] - agents.agents[predicate.agents[i]].lenwid[1] / 2, -Inf, Inf)
                bounds_this = Bounds(threshold + offsets[i+1] + agents.agents[predicate.agents[i+1]].lenwid[1] / 2, Inf, -Inf, Inf)

                apply_bounds!(agents.agents[predicate.agents[i]].states[k], bounds_prev)
                apply_bounds!(agents.agents[predicate.agents[i+1]].states[k], bounds_this)

                min_prev = threshold
                max_prev = max_this
            else
                # @info "no handling necessary"
                min_prev = min_this
                max_prev = max_this
            end
        end
    else # optimization
        M = length(predicate.agents)
        s_min = Vector{Float64}(undef, M)
        s_max = Vector{Float64}(undef, M)
        
        @inbounds for i=1:M
            s_min[i], s_max[i] = s(agents.agents[predicate.agents[i]].states[k])
        end

        s_min += offsets
        s_max += offsets
        s_min_opt, s_max_opt = optimize_partition(s_min, s_max, grb_env)
        
        @inbounds for i=1:M
            agent = agents.agents[predicate.agents[i]]
            if s_min_opt[i] > s_min[i] + 1e-3
                limit!(agent.states[k], Limit(State(s_min_opt[i] - agent.lenwid[1]/2 - offsets[i], 0), SVector{2, Float64}(1, 0)))
            end
            if s_max_opt[i] < s_max[i] - 1e-3
                limit!(agent.states[k], Limit(State(s_max_opt[i] + agent.lenwid[1]/2 - offsets[i], 0), SVector{2, Float64}(-1, 0)))
            end
        end
    end

    return nothing
end

struct SafeDistance <: PredicateMulti
    agents::Vector{AgentID}

    function SafeDistance(agents::AbstractVector{AgentID})
        @assert length(agents) ≥ 2
        return new(agents)
    end
end

function apply_predicate!(
    predicate::SafeDistance,
    agents::AgentsDict,
    k::TimeStep,
    grb_env::Union{Env, Nothing}=nothing,
    unnecessary...
)
    # assert BehindAgent
    apply_predicate!(BehindAgent(predicate.agents), agents, k, grb_env)

    M = length(predicate.agents)

    # offsets
    offsets = [agents.offset[predicate.agents[i], predicate.agents[i+1]] for i=1:M-1] # TODO check sign!
    
    # compute s_break
    s_break_min = Vector{Float64}(undef, M)
    s_break_max = Vector{Float64}(undef, M)
    
    for i in eachindex(predicate.agents)
        agent_id = predicate.agents[i]
        s_break_min[i], s_break_max[i] = s_break(agents.agents[agent_id].states[k], agents.agents[agent_id].a_lb)
    end
    
    p = plot();
    for agent_id in predicate.agents
        plot!(p, plot_data(agents.agents[agent_id].states[k])); 
    end

    # mediate in case of conflicts
    if isnothing(grb_env)
        for i in 1:M-1
            if s_break_max[i] > s_break_min[i+1] + offsets[i] # TODO check sign!
                # mediate threshold
                s_threshold = (s_break_min[i+1] + offsets[i]) * i/M + s_break_max[i] * (1 - i/M)

                # shrink reachable sets to comply with predicates
                safe_distance_behind!(agents.agents[predicate.agents[i]].states[k], s_threshold - agents.agents[predicate.agents[i]].lenwid[1]/2, agents.agents[predicate.agents[i]].a_lb, agents.agents[predicate.agents[i]].v_ub)
                safe_distance_front!(agents.agents[predicate.agents[i+1]].states[k], s_threshold + agents.agents[predicate.agents[i+1]].lenwid[1]/2+ offsets[i], agents.agents[predicate.agents[i+1]].a_lb)
            end
        end
    else # optimization based
        cumsum!(offsets, offsets)
        pushfirst!(offsets, 0.0)
        s_break_min += offsets
        s_break_max += offsets
        s_break_min_opt, s_break_max_opt = optimize_partition(s_break_min, s_break_max, grb_env)

        for i in 1:M
            agent = agents.agents[predicate.agents[i]]
            if s_break_min_opt[i] > s_break_min[i] + 1e-3
                safe_distance_front!(agent.states[k], s_break_min_opt[i] + agent.lenwid[1]/2 - offsets[i], agent.a_lb)
            end
            if s_break_max_opt[i] < s_break_max[i] - 1e-3
                safe_distance_behind!(agent.states[k], s_break_max_opt[i] - agent.lenwid[1]/2 - offsets[i], agent.a_lb, agent.v_ub)
            end
        end
    end

    for agent_id in predicate.agents
        plot!(p, plot_data(agents.agents[agent_id].states[k])); 
    end
    display(p)

    return nothing
end

function s(
    cs::ConvexSet
)
    @assert length(cs.vertices) > 0 
    s_min = Inf64
    s_max = -Inf64
    @inbounds for v in cs.vertices
        s = v[1]
        s < s_min ? s_min = s : nothing
        s > s_max ? s_max = s : nothing
    end


    isinf(s_min) && throw(error(cs)) # TODO remove
    isinf(s_max) && throw(error(cs))
    return s_min, s_max
end
function s_break(
    cs::ConvexSet,
    a_lb::Real
)
    @assert length(cs.vertices) > 0
    s_break_min = Inf64
    s_break_max = -Inf64
    @inbounds for v in cs.vertices
        s_break = v[1] - v[2]^2 / (2*a_lb)
        s_break < s_break_min ? s_break_min = s_break : nothing
        s_break > s_break_max ? s_break_max = s_break : nothing
    end

    return s_break_min, s_break_max
end

function safe_distance_behind!(
    cs::ConvexSet,
    s_threshold::Real,
    a_lb::Real,
    v_ub::Real; 
    N::Integer=20 # number of limits
)
    vert_prev = State(s_threshold, 0)
    limit!(cs, Limit(vert_prev, SVector{2, Float64}(-1, 0)))
    for i in 1:N
        v = i/N * v_ub
        vert = State(s_threshold + v^2 / (2*a_lb), v)
        limit!(cs, Limit(vert, rotate_90_ccw(vert - vert_prev)))
        vert_prev = vert
    end
    
    return nothing
end

function safe_distance_front!(
    cs::ConvexSet,
    s_threshold::Real,
    a_lb::Real
)
    s_min = min(cs, 1)
    s_max = max(cs, 1)
    s_lin = (s_min + s_max)/2

    limit = Limit(State(NaN, NaN), SVector{2, Float64}(1, 0))
    if s_lin < s_threshold
        v_lin = sqrt(2*a_lb*(s_lin - s_threshold))
        α = atan(a_lb, v_lin)
        limit = Limit(State(s_lin, v_lin), SVector{2, Float64}(-sin(α), cos(α)))
    else
        @warn "s_thres: $s_threshold \n s_lin: $s_lin"
        # limit = Limit(State(s_threshold, 0), SVector{2, Float64}(1, 0))
        limit = Limit(State(s_threshold, 0), rotate_90_ccw(State(s_threshold, 0) - State(s_min, sqrt(2*a_lb*(s_min - s_threshold)))))
    end
    
    limit!(cs, limit)
    return nothing
end