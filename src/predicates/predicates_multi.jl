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
    unnecessary...
)
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
    
    return nothing
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
    unnecessary...
)
    offsets = [agents.offset[predicate.agents[i], predicate.agents[i+1]] for i=1:length(predicate.agents)-1] # TODO check sign!
    for i = 2:length(offsets)
        offsets[i] = offsets[i-1] + offsets[i]
    end
    pushfirst!(offsets, 0)

    max_prev = max(agents.agents[predicate.agents[1]].states[k], 1) # offset 0 for first vehicle
    min_prev = min(agents.agents[predicate.agents[1]].states[k], 1)

    # TODO consider length of agents before mediation?
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
    unnecessary...
)
    # assert BehindAgent
    apply_predicate!(BehindAgent(predicate.agents), agents, k)
    
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
    
    # mediate in case of conflicts
    for i in 1:M-1
        if s_break_max[i] > s_break_min[i+1] + offsets[i] # TODO check sign!
            # mediate threshold
            s_threshold = (s_break_min[i+1] + offsets[i]) * i/M + s_break_max[i] * (1 - i/M)

            # shrink reachable sets to comply with predicates
            safe_distance_behind!(agents.agents[predicate.agents[i]].states[k], s_threshold - agents.agents[predicate.agents[i]].lenwid[1]/2 * 0, agents.agents[predicate.agents[i]].a_lb, agents.agents[predicate.agents[i]].v_ub)
            safe_distance_front!(agents.agents[predicate.agents[i+1]].states[k], s_threshold + agents.agents[predicate.agents[i+1]].lenwid[1]/2 * 0+ offsets[i], agents.agents[predicate.agents[i+1]].a_lb)
        end
    end

    return nothing
end

function s_break(
    cs::ConvexSet,
    a_lb::Real
)
    @assert length(cs.vertices) > 0
    _, ind_min = findmin(v -> dot(v, SVector{2, Float64}(-a_lb/v[2], 1)), cs.vertices) # slight overapproximation
    _, ind_max = findmax(v -> dot(v, SVector{2, Float64}(-a_lb/v[2], 1)), cs.vertices)

    s_break_min = cs.vertices[ind_min][1] - cs.vertices[ind_min][2]^2 / (2*a_lb)
    s_break_max = cs.vertices[ind_max][1] - cs.vertices[ind_max][2]^2 / (2*a_lb)

    return s_break_min, s_break_max
end

function safe_distance_behind!(
    cs::ConvexSet,
    s_threshold::Real,
    a_lb::Real,
    v_ub::Real
)
    N = 20 # number of support points
    vert_prev = State(s_threshold, 0)
    limit!(cs, Limit(vert_prev, SVector{2, Float64}(-1, 0)))
    for i in 1:N
        v = i/N * v_ub
        vert = State(s_threshold + v^2 / (2*a_lb), v)
        limit!(cs, Limit(vert_prev, rotate_90_ccw(vert - vert_prev)))
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

    limit = Limit(State(NaN, NaN), SVector{2, Float64}(1, 1))
    if s_lin < s_threshold
        v_lin = sqrt(2*a_lb*(s_lin - s_threshold))
        limit = Limit(State(s_lin, v_lin), SVector{2, Float64}(-sin(a_lb/v_lin), cos(a_lb/v_lin)))
    else
        limit = Limit(State(s_threshold, 0), SVector{2, Float64}(1, 0))
    end
    
    limit!(cs, limit)
    return nothing
end