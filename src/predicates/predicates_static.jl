struct OnLanelet <: Predicate
    actor_ego::ActorID
    lanelet::Set{LaneletID} # Lanelet IDs must be sequential -- TODO add specific constructor? 
end

function Bounds( # TODO might be worth memoizing, suited for @generated?
    predicate::OnLanelet,
    actors::ActorsDict
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

struct OnConflictSection <: Predicate
    actor_ego::ActorID
    conflict_section::ConflictSectionID
end

function Bounds(
    predicate::OnConflictSection,
    actors::ActorsDict
)
    s_lb, s_ub = actors.actors[predicate.actor_ego].route.conflict_sections[predicate.conflict_section]

    return Bounds(s_lb, s_ub, -Inf, Inf)
end

struct BeforeConflictSection <: Predicate
    actor_ego::ActorID
    conflict_section::ConflictSectionID
end

function Bounds(
    predicate::BeforeConflictSection,
    actors::ActorsDict
)
    s_ub, _ = actors.actors[predicate.actor_ego].route.conflict_sections[predicate.conflict_section]
 
    return Bounds(-Inf, s_ub, -Inf, Inf)
end

struct BehindConflictSection <: Predicate
    actor_ego::ActorID
    conflict_section::ConflictSectionID
end

function Bounds(
    predicate::BehindConflictSection,
    actors::ActorsDict
)
    _, s_lb = actors.actors[predicate.actor_ego].route.conflict_sections[predicate.conflict_section]
 
    return Bounds(s_lb, Inf, -Inf, Inf)
end