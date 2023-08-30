using ScenarioSynthesis
using Polygons
using Test
using StaticArrays
using Plots

include("runtest_reachability.jl")
include("runtest_coordinates.jl")
include("runtest_geometry.jl")
include("runtest_lanelet_network.jl")
include("runtest_route.jl")
include("runtest_agent.jl")
include("runtest_metric_temporal_logic.jl")
include("runtest_predicates_static.jl")
include("runtest_predicates_dynamic.jl")
include("runtest_synthesis.jl")
include("runtest_visualize.jl")