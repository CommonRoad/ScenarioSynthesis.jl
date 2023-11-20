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
# include("runtest_predicates_optimize_partition.jl")
include("runtest_predicates_type_ranking.jl")
include("runtest_predicates_single.jl")
include("runtest_predicates_multi.jl")
include("runtest_synthesis.jl")
include("runtest_visualize.jl")