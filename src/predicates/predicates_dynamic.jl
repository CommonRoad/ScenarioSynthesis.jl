struct BehindActor <: Predicate 
    actor_ego::ActorID
    actor_other::ActorID
end

function Bounds(
    predicate::BehindActor,
    actors::ActorsDict,
    k::TimeStep,
    ψ::Real=1.0
)
    actor_ego = predicate.actor_ego
    actor_other = predicate.actor_other

    s_other = get_lower_lim(actors.actors[actor_other].states[k], 1, ψ)
    s_offset = actors.offset[(actor_other, actor_ego)]

    s_max = s_other + s_offset - actors.actors[actor_ego].lenwid[1] / 2 - actors.actors[actor_other].lenwid[1] / 2
    
    return Bounds(-Inf, s_max, -Inf, Inf)
end

struct SlowerActor <: Predicate
    actor_ego::ActorID
    actor_other::ActorID
end

function Bounds(
    predicate::SlowerActor,
    actors::ActorsDict,
    k::TimeStep,
    ψ::Real=1.0
)
    v_other = get_lower_lim(actors.actors[predicate.actor_other].states[k], 2, ψ)

    v_max = v_other

    return Bounds(-Inf, Inf, -Inf, v_max)
end