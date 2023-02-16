include("convex_set.jl")
export ConvexSet, is_counterclockwise_convex

include("propagate.jl")
export propagate, propagate!, propagate_backward, propagate_backward!

include("operations.jl")
export upper_lim!, lower_lim!, get_upper_lim, get_lower_lim

include("visualization.jl")
export plot, plot!