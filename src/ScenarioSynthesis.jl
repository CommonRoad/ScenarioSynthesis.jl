module ScenarioSynthesis

using StaticArrays

include("types/Types.jl")
include("actors/Actors.jl")
include("predicates/Predicates.jl")
include("scenarios/Scenarios.jl")
include("synthesis/Synthesis.jl")
include("visualization/Visualization.jl")

export Pos, FCart, FCurv, StateLon, StateLat, StateCurve, Lanelet, LaneletNetwork # types

export Actor, Vehicle # actors

export Predicate, Relation, TrafficRule, IsBehind, IsNextTo, IsInFront, IsOnLanelet, IsOnLane, SpeedLimit, SafeDistance # predicates

export Scenario, Scene # scenarios

# export # synthesis

# export # visualization

end
