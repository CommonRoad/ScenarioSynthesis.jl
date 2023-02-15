include("convex_states.jl")
export ConvexStates, is_convex, is_counter_clockwise

include("propagate.jl")
export propagate, propagate!, propagate_backwards, propagate_backwards!

include("operations.jl")
export upper_lim!, lower_lim!

include("visualization.jl")
export plot, plot!