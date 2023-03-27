abstract type StaticPredicate <: BasicPredicate end

function apply_predicate!(
    predicate::StaticPredicate, 
    actors::ActorsDict, 
    k::TimeStep,
    unnecessary...
)
    bounds = Bounds(predicate, actors)
    apply_bounds!(actors.actors[predicate.actor_ego].states[k], bounds)
    return nothing
end

struct OnLanelet <: StaticPredicate
    actor_ego::ActorID
    lanelet::Set{LaneletID} # Lanelet IDs must be sequential -- TODO add specific constructor? 
end

function Bounds( # TODO might be worth memoizing, suited for @generated?
    predicate::OnLanelet,
    actors::ActorsDict,
    unnecessary...
)
    s_lb = Inf
    s_ub = -Inf

    route = actors.actors[predicate.actor_ego].route

    for lt in predicate.lanelet
        s_lb_temp, s_ub_temp, _ = route.lanelet_interval[lt]
        s_lb = min(s_lb, s_lb_temp)
        s_ub = max(s_ub, s_ub_temp)
    end

    return Bounds(s_lb, s_ub, -Inf, Inf)
end

struct OnConflictSection <: StaticPredicate
    actor_ego::ActorID
    conflict_section::ConflictSectionID
end

function Bounds(
    predicate::OnConflictSection,
    actors::ActorsDict, 
    unnecessary...
)
    s_lb, s_ub = actors.actors[predicate.actor_ego].route.conflict_sections[predicate.conflict_section]
    s_lb -= actors.actors[predicate.actor_ego].lenwid[1] / 2
    s_ub += actors.actors[predicate.actor_ego].lenwid[1] / 2

    return Bounds(s_lb, s_ub, -Inf, Inf)
end

struct BeforeConflictSection <: StaticPredicate
    actor_ego::ActorID
    conflict_section::ConflictSectionID
end

function Bounds(
    predicate::BeforeConflictSection,
    actors::ActorsDict, 
    unnecessary...
)
    s_ub, _ = actors.actors[predicate.actor_ego].route.conflict_sections[predicate.conflict_section]
    s_ub -= actors.actors[predicate.actor_ego].lenwid[1] / 2
 
    return Bounds(-Inf, s_ub, -Inf, Inf)
end

struct BehindConflictSection <: StaticPredicate
    actor_ego::ActorID
    conflict_section::ConflictSectionID
end

function Bounds(
    predicate::BehindConflictSection,
    actors::ActorsDict,
    unnecessary...
)
    _, s_lb = actors.actors[predicate.actor_ego].route.conflict_sections[predicate.conflict_section]
    s_lb += actors.actors[predicate.actor_ego].lenwid[1] / 2
 
    return Bounds(s_lb, Inf, -Inf, Inf)
end

struct VelocityLimits <: StaticPredicate
    actor_ego::ActorID
end

function Bounds(
    predicate::VelocityLimits,
    actors::ActorsDict,
    unnecessary...
)
    return Bounds(-Inf, Inf, actors.actors[predicate.actor_ego].v_lb, actors.actors[predicate.actor_ego].v_ub)
end

struct PositionLimits <: StaticPredicate
    actor_ego::ActorID
end

function Bounds(
    predicate::PositionLimits,
    actors::ActorsDict,
    unnecessary...
)
    return Bounds(actors.actors[predicate.actor_ego].route.frame.cum_dst[1], actors.actors[predicate.actor_ego].route.frame.cum_dst[end], -Inf, Inf)
end

struct StateLimits <: StaticPredicate
    actor_ego::ActorID
end

function Bounds(
    predicate::StateLimits,
    actors::ActorsDict,
    unnecessary...
)
    return Bounds(
        actors.actors[predicate.actor_ego].route.frame.cum_dst[1], 
        actors.actors[predicate.actor_ego].route.frame.cum_dst[end],
        actors.actors[predicate.actor_ego].v_lb,
        actors.actors[predicate.actor_ego].v_ub
    )
end