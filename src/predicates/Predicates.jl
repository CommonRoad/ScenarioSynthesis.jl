const TimeStep = Int64
export TimeStep

#=
struct GenericBasePredicate <: BasicPredicate
    agent_ego::AgentID # TODO or ::Agent ??
    agent_other::AgentID
    lanelet::LaneletID
    conflict_section::ConflictSectionID
end
=#

include("metric_temporal_logic.jl")
export Predicate, BasicPredicate, MTLPredicate, LogicOperator, And, Or, Not, Implies, TimeOperator, Once, Future, Globally, Previously, Interval, mtl2config, explore_mtl!, jump_to_next_basic_predicate!, simplify!, Relative, Absolute

include("bounds.jl")
export Bounds, apply_bounds!, apply_predicate!

include("predicates_single.jl")
export PredicateSingle, OnLanelet, OnConflictSection, BeforeConflictSection, BehindConflictSection, VelocityLimits, PositionLimits, StateLimits

include("predicates_multi.jl")
export PredicateMulti, BehindAgent, InFrontOfAgent, SlowerAgent, FasterAgent

include("type_ranking.jl")
export type_ranking

include("higher_level_predicates.jl")