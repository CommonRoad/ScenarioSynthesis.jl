abstract type DynamicPredicate <: BasicPredicate end

struct BehindActor <: DynamicPredicate 
    actor_ego::ActorID
    actor_other::ActorID
end

function apply_predicate!(
    predicate::BehindActor,
    actors::ActorsDict,
    k::TimeStep,
    ψ::Real=0.5 # 0 (cut the one in front) ... 1 (cut the one behind)
)
    @assert 0 ≤ ψ ≤ 1

    actor_ego = actors.actors[predicate.actor_ego]
    actor_other = actors.actors[predicate.actor_other]

    s_ego_min, s_ego_max = Inf, -Inf
    for vert in actor_ego.states[k].vertices
        s_ego_min = min(s_ego_min, vert[1])
        s_ego_max = max(s_ego_max, vert[1])
    end
    s_other_min, s_other_max = Inf, -Inf 
    for vert in actor_other.states[k].vertices
        s_other_min = min(s_other_min, vert[1])
        s_other_max = max(s_other_max, vert[1])
    end
    
    s_other_min += actors.offset[(predicate.actor_ego, predicate.actor_other)]
    s_other_max += actors.offset[(predicate.actor_ego, predicate.actor_other)]

    s_ego_max < s_other_min && return nothing # no collision at all
    s_ego_max = min(s_ego_max, s_other_max)
    s_other_min = max(s_ego_min, s_other_min)

    centr = (1-ψ) * s_ego_max + ψ * s_other_min

    s_ego_ub = centr - actor_ego.lenwid[1] / 2 - actor_other.lenwid[1] / 2
    s_other_lb = centr + actors.offset[(predicate.actor_ego, predicate.actor_other)] + actor_ego.lenwid[1] / 2 + actor_other.lenwid[1] / 2

    bounds_ego = Bounds(-Inf, s_ego_ub, -Inf, Inf)
    bounds_other = Bounds(s_other_lb, Inf, -Inf, Inf)

    apply_bounds!(actor_ego.states[k], bounds_ego)
    apply_bounds!(actor_other.states[k], bounds_other)
    
    return nothing
end

struct SlowerActor <: DynamicPredicate
    actor_ego::ActorID
    actor_other::ActorID
end

function apply_predicate!(
    predicate::SlowerActor,
    actors::ActorsDict,
    k::TimeStep,
    ψ::Real=0.5 # 0 (cut the faster one) ... 1 (cut the slower one)
)
    @assert 0 ≤ ψ ≤ 1

    actor_ego = actors.actors[predicate.actor_ego]
    actor_other = actors.actors[predicate.actor_other]

    v_ego_min, v_ego_max = Inf, -Inf
    for vert in actor_ego.states[k].vertices
        v_ego_min = min(v_ego_min, vert[2])
        v_ego_max = max(v_ego_max, vert[2])
    end
    v_other_min, v_other_max = Inf, -Inf 
    for vert in actor_other.states[k].vertices
        v_other_min = min(v_other_min, vert[2])
        v_other_max = max(v_other_max, vert[2])
    end

    v_ego_max < v_other_min && return nothing
    v_ego_max = min(v_ego_max, v_other_max)
    v_other_min = max(v_ego_min, v_other_min)

    centr = (1-ψ) * v_ego_max + ψ * v_other_min

    v_ego_ub = centr
    v_other_lb = centr

    bounds_ego = Bounds(-Inf, Inf, -Inf, v_ego_ub)
    bounds_other = Bounds(-Inf, Inf, v_other_lb, Inf)

    apply_bounds!(actor_ego.states[k], bounds_ego)
    apply_bounds!(actor_other.states[k], bounds_other)
    
    return nothing
end