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
export Predicate, BasicPredicate, MTLPredicate, LogicOperator, And, Or, Not, Implies, TimeOperator, Once, Future, Globally, Previously, Interval, mtl2config, explore_mtl!, jump_to_next_basic_predicate!, simplify!, Relative, Absolute

include("bounds.jl")
export Bounds, apply_bounds!, apply_predicate!

include("predicates_static.jl")
export StaticPredicate, OnLanelet, OnConflictSection, BeforeConflictSection, BehindConflictSection, VelocityLimits, PositionLimits, StateLimits

include("predicates_dynamic.jl")
export DynamicPredicate, BehindActor, InFrontOfActor, SlowerActor, FasterActor

include("type_ranking.jl")
export type_ranking

include("higher_level_predicates.jl")