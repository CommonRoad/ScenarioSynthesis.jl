struct OnLanelet <: Predicate
    actor_ego::ActorID
    lanelet::LaneletID
end

function Bounds( # TODO might be worth memoizing, suited for @generated?
    predicate::OnLanelet,
    actors::ActorsDict
)
    s_min = -Inf
    s_max = Inf

    route = actors[predicate.actor_ego].route

    is_found = false
    @inbounds for i in eachindex(route.route) # TODO use new data structure instead
        if route.route[i] == predicate.lanelet
            s_min = route.transition_points[i]
            s_max = route.transition_points[i+1]
            is_found = true
            break
        end
    end
    
    is_found || throw(error("predicate cannot be fulfilled. predicate.lanelet not part of actor_ego.route.")) # TODO add relaxed handling? 

    return Bounds(s_min, s_max, -Inf, Inf)
end

struct OnConflictSection <: Predicate
    actor_ego::ActorID
    conflict_section::ConflictSection
end

function Bounds(
    predicate::OnConflictSection,
    actors::ActorsDict
)
    s_min, s_max = actors.actors[predicate.actor_ego].conflict_sections[predicate.conflict_section]

    return Bounds(s_min, s_max, -Inf, Inf)
end

struct BeforeConflictSection <: Predicate
    actor_ego::ActorID
    OnConflictSection::ConflictSectionID
end

function Bounds(
    predicate::BeforeConflictSection,
    actors::ActorsDict
)
    s_max, _ = actors.actors[predicate.actor_ego].conflict_sections[predicate.conflict_section]
 
    return Bounds(-Inf, s_max, -Inf, Inf)
end

struct BehindConflictSection <: Predicate
    actor_ego::ActorID
    OnConflictSection::ConflictSectionID
end

function Bounds(
    predicate::BehindConflictSection,
    actors::ActorsDict
)
    _, s_min = actors.actors[predicate.actor_ego].conflict_sections[predicate.conflict_section]
 
    return Bounds(s_min, Inf, -Inf, Inf)
end