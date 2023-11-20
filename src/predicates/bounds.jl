struct Bounds
    s_lb::Float64
    s_ub::Float64
    v_lb::Float64
    v_ub::Float64
end

function apply_bounds!( # TODO are there faster algorithms than sequential processing ?
    cs::ConvexSet,
    bounds::Bounds
)
    isinf(bounds.s_lb) || limit!(cs, Limit(State(bounds.s_lb, 0), SVector{2, Float64}(1, 0)))
    isinf(bounds.s_ub) || limit!(cs, Limit(State(bounds.s_ub, 0), SVector{2, Float64}(-1, 0)))
    isinf(bounds.v_lb) || limit!(cs, Limit(State(0, bounds.v_lb), SVector{2, Float64}(0, 1)))
    isinf(bounds.v_ub) || limit!(cs, Limit(State(0, bounds.v_ub), SVector{2, Float64}(0, -1)))
    return nothing
end