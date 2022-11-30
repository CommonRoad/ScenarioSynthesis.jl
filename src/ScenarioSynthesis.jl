module ScenarioSynthesis

# ENV["JULIA_PYTHONCALL_EXE"] = "/home/florian/anaconda3/envs/pycall/bin/python3.10" # TODO why does this not work

@info "pythoncall exe set to: $(ENV["JULIA_PYTHONCALL_EXE"])"

using DataStructures
using PythonCall
using StaticArrays

import PythonCall.pyconvert_add_rule
import PythonCall.PYCONVERT_PRIORITY_NORMAL

include("types/Types.jl")
include("actors/Actors.jl")
include("predicates/Predicates.jl")
include("scenarios/Scenarios.jl")
include("synthesis/Synthesis.jl")
include("visualization/Visualization.jl")

export Pos, FCart, FCurv, StateLon, StateLat, StateCurve, LaneSectionID, LaneSection, LaneSectionNetwork, lsn_from_path # types

export Actor, Vehicle # actors

export Predicate, Relation, TrafficRule, IsBehind, IsNextTo, IsInFront, IsOnLanelet, IsOnLane, SpeedLimit, SafeDistance # predicates

export Scenario, Scene # scenarios

# export # synthesis

# export # visualization
end
