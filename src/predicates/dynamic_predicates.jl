struct IsBehindActor <: Predicate 
    actor_ego::ActorID
    actor_other::ActorID
end

function Bounds(
    predicate::IsBehindActor,
    actors::ActorsDict,
    k::TimeStep,
    ψ::Real=1.0
)
    s_other = get_lower_lim(actors.actors[predicate.actor_other].states[k], 1, ψ)
    s_offset = 23.0 # offset of longitudial coordinates of actor_ego and actor_other

    s_max = s_other + s_offset # TODO check sign 
    
    return Bounds(-Inf, s_max, -Inf, Inf)
end