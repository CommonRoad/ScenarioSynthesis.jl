module ScenarioSynthesis

# __precompile__(false)
# @info "pythoncall exe set to: $(ENV["JULIA_PYTHONCALL_EXE"])"
using Polygons
import StaticArrays: FieldVector, SVector, SMatrix
import LinearAlgebra: norm, dot, cross

include("reachability/Reachability.jl")
include("types/Types.jl") # TODO rename to CommonRoad? Map? LaneletNetwork? Environment? 
include("predicates/Predicates.jl")
include("synthesis/Synthesis.jl")
include("visualization/Visualization.jl")
include("moritz/Moritz.jl")
include("benchmarking/Benchmarking.jl")

end
