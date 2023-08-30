include("convex_set.jl")

include("propagate.jl")
export propagate, propagate!, propagate_backward, propagate_backward!

include("operations.jl")
export upper_lim!, lower_lim!, get_upper_lim, get_lower_lim, intersection

include("visualization.jl")
export plot_data, plot!