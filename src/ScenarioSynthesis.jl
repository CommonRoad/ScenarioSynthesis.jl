module ScenarioSynthesis

# __precompile__(false)
# @info "pythoncall exe set to: $(ENV["JULIA_PYTHONCALL_EXE"])"

include("types/Types.jl")
include("scenarios/Scenarios.jl")
# include("predicates/Predicates.jl")
include("synthesis/Synthesis.jl")
include("visualization/Visualization.jl")

end
