const TimeStep = Int64
export TimeStep

#=
struct GenericBasePredicate <: BasicPredicate
    actor_ego::ActorID # TODO or ::Actor ??
    actor_other::ActorID
    lanelet::LaneletID
    conflict_section::ConflictSectionID
end
=#

include("metric_temporal_logic.jl")
export Predicate, BasicPredicate, MTLPredicate, LogicOperator, And, Or, Not, Implies, TimeOperator, Once, Future, Globally, Previously, Interval

include("bounds.jl")
export Bounds, apply_bounds!

include("predicates_static.jl")
export OnLanelet, OnConflictSection, BeforeConflictSection, BehindConflictSection, VelocityLimits

include("predicates_dynamic.jl")
export BehindActor, SlowerActor

include("higher_level_predicates.jl")