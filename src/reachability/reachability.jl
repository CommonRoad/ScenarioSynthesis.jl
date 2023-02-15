include("convex_set.jl")
export ConvexSet, is_convex, is_counter_clockwise

include("propagate.jl")
export propagate, propagate!, propagate_backward, propagate_backward!

include("operations.jl")
export upper_lim!, lower_lim!

include("visualization.jl")
export plot, plot!