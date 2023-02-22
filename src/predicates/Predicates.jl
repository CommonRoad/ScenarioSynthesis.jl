const TimeStep = Int64

abstract type Predicate end

struct Bounds
    s_lb::Float64
    s_ub::Float64
    v_lb::Float64
    v_ub::Float64
end

#=
struct GenericPredicate <: Predicate
    actor_ego::ActorID # TODO or ::Actor ??
    actor_other::ActorID
    lanelet::LaneletID
    conflict_section::ConflictSectionID
end

function Bounds(
    Predicate::GenericPredicate,
    actors::ActorsDict,
    ...,
    ψ::Real = 1.0 # min. degree of statisfaction
)
    return Bounds(...)
end
=#

export TimeStep, Predciate, Bounds

include("predicates_static.jl")
export OnLanelet, OnConflictSection, BeforeConflictSection, BehindConflictSection

include("predicates_dynamic.jl")
export BehindActor, SlowerActor