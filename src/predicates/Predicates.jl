const TimeStep = Int64

abstract type Predicate end

struct Bounds
    s_min::Float64
    s_max::Float64
    v_min::Float64
    v_max::Float64
end

#=
struct GenericPredicate <: Predicate
    actor_ego::ActorID # TODO or ::Actor ??
    actor_other::ActorID
    lanelet::LaneletID
    conflict_section::ConflictSectionID
end
=#

export TimeStep, Predciate, Bounds

include("static_predicates.jl")
include("dynamic_predicates.jl")