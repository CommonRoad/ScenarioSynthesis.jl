"""
    propagate

Assumptions: 
- constant acceleration inbetween time-steps. 
- input set must be convex. 
- A linear system model (state space)
"""
function propagate(
    cs::ConvexSet,
    A::SMatrix,
    a_lb::Real,
    a_ub::Real,
    Δt::Real
)
    # time-step forward
    fundamental_matrix = exp(A*Δt)
    output = affine_transformation(cs, fundamental_matrix)

    # minkowski
    minkowski_element = LineSegment(State(a_ub / 2 * Δt^2, a_ub * Δt), State(a_lb / 2 * Δt^2, a_lb * Δt))
    minkowski_sum!(output, minkowski_element)

    return output
end

function propagate!(
    cs::ConvexSet,
    A::SMatrix,
    a_lb::Real,
    a_ub::Real,
    Δt::Real
)
    # time-step forward
    fundamental_matrix = exp(A*Δt)
    affine_transformation!(cs, fundamental_matrix)

    # minkowski_element
    minkowski_element = LineSegment(State(a_ub / 2 * Δt^2, a_ub * Δt), State(a_lb / 2 * Δt^2, a_lb * Δt))
    minkowski_sum!(cs, minkowski_element)

    return nothing
end

function propagate_backward(
    cs::ConvexSet,
    A::SMatrix,
    a_lb::Real,
    a_ub::Real,
    Δt::Real
)
    # minkowski
    minkowski_element = LineSegment(-State(a_ub / 2 * Δt^2, a_ub * Δt), -State(a_lb / 2 * Δt^2, a_lb * Δt))
    output = minkowski_sum(cs, minkowski_element)

    # time-step backward
    fundamental_matrix_inv = exp(A*Δt)^-1
    affine_transformation!(output, fundamental_matrix_inv)

    return output
end

function propagate_backward!(
    cs::ConvexSet,
    A::SMatrix,
    a_lb::Real,
    a_ub::Real,
    Δt::Real
)
    # minkowski
    minkowski_element = LineSegment(-State(a_ub / 2 * Δt^2, a_ub * Δt), -State(a_lb / 2 * Δt^2, a_lb * Δt))
    minkowski_sum!(cs, minkowski_element)

    # time-step backward
    fundamental_matrix_inv = exp(A*Δt)^-1
    affine_transformation!(cs, fundamental_matrix_inv)

    return nothing
end