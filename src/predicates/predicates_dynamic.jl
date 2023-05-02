abstract type DynamicPredicate <: BasicPredicate end

struct BehindActor <: DynamicPredicate 
    actors::Vector{ActorID}

    function BehindActor(actors::AbstractVector{ActorID})
        @assert length(actors) ≥ 2
        return new(actors)        
    end
end

function apply_predicate!(
    predicate::BehindActor,
    actors::ActorsDict,
    k::TimeStep,
    unnecessary...
)

    offsets = [actors.offset[predicate.actors[i], predicate.actors[i+1]] for i=1:length(predicate.actors)-1] # TODO check sign!
    for i = 2:length(offsets)
        offsets[i] = offsets[i-1] + offsets[i]
    end
    pushfirst!(offsets, 0)

    max_prev = max(actors.actors[predicate.actors[1]].states[k], 1) # offset 0 for first vehicle
    min_prev = min(actors.actors[predicate.actors[1]].states[k], 1)

    # TODO consider length of actors
    for i in 1:length(predicate.actors)-1
        max_this = max(actors.actors[predicate.actors[i+1]].states[k], 1) - offsets[i+1] 
        min_this = min(actors.actors[predicate.actors[i+1]].states[k], 1) - offsets[i+1] 

        min_this = max(min_prev, min_this)
        max_prev = min(max_prev, max_this)

        # @info min_prev, max_prev, min_this, max_this
        if min_this + actors.actors[predicate.actors[i]].lenwid[1] / 2 < max_prev - actors.actors[predicate.actors[i+1]].lenwid[1] / 2
            ψ = i / length(predicate.actors)
            # TODO one should consider the length of the actors -- matters if actors' length substantially differs
            threshold = ψ * (max_prev - actors.actors[predicate.actors[i+1]].lenwid[1] / 2) + (1-ψ) * (min_this + actors.actors[predicate.actors[i]].lenwid[1] / 2)
            # @info threshold
        
            bounds_prev = Bounds(-Inf, threshold + offsets[i] - actors.actors[predicate.actors[i]].lenwid[1] / 2, -Inf, Inf)
            bounds_this = Bounds(threshold + offsets[i+1] + actors.actors[predicate.actors[i+1]].lenwid[1] / 2, Inf, -Inf, Inf)

            apply_bounds!(actors.actors[predicate.actors[i]].states[k], bounds_prev)
            apply_bounds!(actors.actors[predicate.actors[i+1]].states[k], bounds_this)

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

struct SlowerActor <: DynamicPredicate
    actors::Vector{ActorID}
    function SlowerActor(actors::AbstractVector{ActorID})
        @assert length(actors) ≥ 2
        return new(actors)
    end
end

function apply_predicate!(
    predicate::SlowerActor,
    actors::ActorsDict,
    k::TimeStep,
    unnecessary...
)
    # @assert length(predicate.actors) ≥ 2 # already checked by constructor!
    max_prev = max(actors.actors[predicate.actors[1]].states[k], 2)
    min_prev = min(actors.actors[predicate.actors[1]].states[k], 2)
    
    for i in 1:length(predicate.actors)-1
        max_this = max(actors.actors[predicate.actors[i+1]].states[k], 2)
        min_this = min(actors.actors[predicate.actors[i+1]].states[k], 2)

        min_this = max(min_prev, min_this)
        max_prev = min(max_prev, max_this)

        @info min_prev, max_prev, min_this, max_this
        if min_this < max_prev
            ψ = i / length(predicate.actors)
            threshold = ψ * max_prev + (1-ψ) * min_this
            @info threshold
        
            bounds_prev = Bounds(-Inf, Inf, -Inf, threshold)    
            bounds_this = Bounds(-Inf, Inf, threshold, Inf)  

            apply_bounds!(actors.actors[predicate.actors[i]].states[k], bounds_prev)
            apply_bounds!(actors.actors[predicate.actors[i+1]].states[k], bounds_this)

            min_prev = threshold
            max_prev = max_this
        else
            min_prev = min_this
            max_prev = max_this
        end

    end
    
    return nothing
end