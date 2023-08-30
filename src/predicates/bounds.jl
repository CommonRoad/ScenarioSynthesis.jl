struct Bounds
    s_lb::Float64
    s_ub::Float64
    v_lb::Float64
    v_ub::Float64
end

#=
function Bounds(
    Predicate::GenericPredicate,
    agents::AgentsDict,
    k::TimeStep,
    ψ::Real = 1.0, # min. degree of statisfaction
    unnecessary...
)
    return Bounds(...)
end
=#

function apply_bounds!( # TODO are there faster algorithms than sequential processing ?
    cs::ConvexSet,
    bounds::Bounds
)
    isinf(bounds.s_lb) || lower_lim!(cs, 1, bounds.s_lb)
    isinf(bounds.s_ub) || upper_lim!(cs, 1, bounds.s_ub)
    isinf(bounds.v_lb) || lower_lim!(cs, 2, bounds.v_lb)
    isinf(bounds.v_ub) || upper_lim!(cs, 2, bounds.v_ub)
    return nothing
end