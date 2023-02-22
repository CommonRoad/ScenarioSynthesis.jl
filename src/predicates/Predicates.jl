const TimeStep = Int64

abstract type Predicate end

#=
struct GenericPredicate <: Predicate
    actor_ego::ActorID # TODO or ::Actor ??
    actor_other::ActorID
    lanelet::LaneletID
    conflict_section::ConflictSectionID
end
=#

export TimeStep, Predicate

include("bounds.jl")
export Bounds, apply_bounds!

include("predicates_static.jl")
export OnLanelet, OnConflictSection, BeforeConflictSection, BehindConflictSection, VelocityLimits

include("predicates_dynamic.jl")
export BehindActor, SlowerActor