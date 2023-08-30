abstract type PredicateMulti <: BasicPredicate end

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

    # TODO consider length of agents
    for i in 1:length(predicate.agents)-1
        max_this = max(agents.agents[predicate.agents[i+1]].states[k], 1) - offsets[i+1] 
        min_this = min(agents.agents[predicate.agents[i+1]].states[k], 1) - offsets[i+1] 

        min_this = max(min_prev, min_this)
        max_prev = min(max_prev, max_this)

        # @info min_prev, max_prev, min_this, max_this
        if min_this + agents.agents[predicate.agents[i]].lenwid[1] / 2 < max_prev - agents.agents[predicate.agents[i+1]].lenwid[1] / 2
            ψ = i / length(predicate.agents)
            # TODO one should consider the length of the agents -- matters if agents' length substantially differs
            threshold = ψ * (max_prev - agents.agents[predicate.agents[i+1]].lenwid[1] / 2) + (1-ψ) * (min_this + agents.agents[predicate.agents[i]].lenwid[1] / 2)
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
    # @assert length(predicate.agents) ≥ 2 # already checked by constructor!
    max_prev = max(agents.agents[predicate.agents[1]].states[k], 2)
    min_prev = min(agents.agents[predicate.agents[1]].states[k], 2)
    
    for i in 1:length(predicate.agents)-1
        max_this = max(agents.agents[predicate.agents[i+1]].states[k], 2)
        min_this = min(agents.agents[predicate.agents[i+1]].states[k], 2)

        min_this = max(min_prev, min_this)
        max_prev = min(max_prev, max_this)

        @info min_prev, max_prev, min_this, max_this
        if min_this < max_prev
            ψ = i / length(predicate.agents)
            threshold = ψ * max_prev + (1-ψ) * min_this
            @info threshold
        
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