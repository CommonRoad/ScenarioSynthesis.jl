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

end
