"""
    propagate

Assumptions: 
- constant acceleration inbetween time-steps. 
- input set must be convex. 
- A linear system model (state space)
"""
function propagate(
    cs::ConvexSet, 
    A::SMatrix, # TODO add SMatrix{2, 2, Float64, 4}(0, 0, 1, 0) as default? 
    a_ub::Real, # TODO change order to match actor defs
    a_lb::Real, 
    Δt::Real
)
    input_set = copy(cs.vertices)

    # time-step forward
    fundamental_matrix = exp(A*Δt)
    @inbounds for i in eachindex(input_set)
        input_set[i] = fundamental_matrix * input_set[i]
    end

    # minkowski
    accelerate = SVector{2,Float64}(a_ub / 2 * Δt^2, a_ub * Δt)
    decelerate = SVector{2,Float64}(a_lb / 2 * Δt^2, a_lb * Δt)
    minkowski_vec = SVector{2,Float64}(-2 / Δt, 1) # rotated by 90°
    
    output_set = Vector{SVector{2, Float64}}(undef, length(input_set)+2)

    counter = 1
    @inbounds for i in eachindex(input_set)
        vec_to_i = input_set[i] - cycle(input_set, i-1)
        vec_from_i = cycle(input_set, i+1) - input_set[i]
        dot_to_i = dot(vec_to_i, minkowski_vec)
        dot_from_i = dot(vec_from_i, minkowski_vec) 
        
        if dot_to_i ≤ 0 && dot_from_i ≤ 0 
            output_set[counter] = input_set[i] + decelerate
        elseif dot_to_i ≤ 0 && dot_from_i ≥ 0 
            output_set[counter] = input_set[i] + decelerate
            counter += 1
            output_set[counter] = input_set[i] + accelerate
        elseif dot_to_i ≥ 0 && dot_from_i ≤ 0 
            output_set[counter] = input_set[i] + accelerate
            counter += 1
            output_set[counter] = input_set[i] + decelerate
        elseif dot_to_i ≥ 0 && dot_from_i ≥ 0 
            output_set[counter] = input_set[i] + accelerate
        end
        counter += 1
    end

    return ConvexSet(output_set, false, false)
end

function propagate!( # more readable implementation in previous commit -- this one is optimized for few allocations
    cs::ConvexSet, 
    A::SMatrix, 
    a_ub::Real, 
    a_lb::Real, 
    Δt::Real
)
    output_set = cs.vertices
    leninput = length(cs.vertices)
    #sizehint!(output_set, leninput+2)

    # time-step forward
    fundamental_matrix = exp(A*Δt)
    @inbounds for i in eachindex(output_set)
        output_set[i] = fundamental_matrix * output_set[i]
    end

    # minkowski
    accelerate = SVector{2,Float64}(a_ub / 2 * Δt^2, a_ub * Δt)
    decelerate = SVector{2,Float64}(a_lb / 2 * Δt^2, a_lb * Δt)
    minkowski_vec = SVector{2,Float64}(-2 / Δt, 1) # rotated by 90°

    counter = 1
    previous_correction = SVector{2, Float64}(0, 0)
    first_correction = SVector{2, Float64}(0, 0)
    next_correction = SVector{2, Float64}(0, 0)

    # iteration
    @inbounds for i in 1:leninput
        i==leninput ? next_correction = first_correction : nothing

        vec_to_i = output_set[counter] - (cycle(output_set, counter-1) - previous_correction)
        vec_from_i = (cycle(output_set, counter+1) - next_correction) - output_set[counter]
        dot_to_i = dot(vec_to_i, minkowski_vec)
        dot_from_i = dot(vec_from_i, minkowski_vec) 
        
        if dot_to_i ≤ 0 && dot_from_i ≤ 0 
            output_set[counter] = output_set[counter] + decelerate
            previous_correction = decelerate
        elseif dot_to_i ≤ 0 && dot_from_i ≥ 0 
            orig = output_set[counter]
            output_set[counter] = orig + decelerate
            counter += 1
            insert!(output_set, counter, orig + accelerate)
            previous_correction = accelerate
        elseif dot_to_i ≥ 0 && dot_from_i ≤ 0
            orig = output_set[counter]
            output_set[counter] = orig + accelerate
            counter += 1
            insert!(output_set, counter, orig + decelerate)
            previous_correction = decelerate
        elseif dot_to_i ≥ 0 && dot_from_i ≥ 0 
            output_set[counter] = output_set[counter] + accelerate
            previous_correction = accelerate
        end
        counter += 1
        i==1 ? first_correction = previous_correction : nothing
    end

    return nothing
end

"""
    backwards

"""
function propagate_backward(
    cs::ConvexSet,
    A::SMatrix,
    a_ub::Real,
    a_lb::Real,
    Δt::Real
)
    input_set = cs.vertices

    # minkowski
    accelerate = -SVector{2,Float64}(a_ub / 2 * Δt^2, a_ub * Δt)
    decelerate = -SVector{2,Float64}(a_lb / 2 * Δt^2, a_lb * Δt)
    minkowski_vec = SVector{2,Float64}(-2 / Δt, 1) # rotated by 90°

    output_set = Vector{SVector{2, Float64}}(undef, length(input_set)+2)

    counter = 1
    @inbounds for i in eachindex(input_set)
        vec_to_i = input_set[i] - cycle(input_set, i-1)
        vec_from_i = cycle(input_set, i+1) - input_set[i]
        dot_to_i = dot(vec_to_i, minkowski_vec)
        dot_from_i = dot(vec_from_i, minkowski_vec) 
        
        if dot_to_i ≤ 0 && dot_from_i ≤ 0 
            output_set[counter] = input_set[i] + accelerate
        elseif dot_to_i ≤ 0 && dot_from_i ≥ 0 
            output_set[counter] = input_set[i] + accelerate
            counter += 1
            output_set[counter] = input_set[i] + decelerate
        elseif dot_to_i ≥ 0 && dot_from_i ≤ 0 
            output_set[counter] = input_set[i] + decelerate
            counter += 1
            output_set[counter] = input_set[i] + accelerate
        elseif dot_to_i ≥ 0 && dot_from_i ≥ 0 
            output_set[counter] = input_set[i] + decelerate
        end
        counter += 1
    end

    # time-step backward
    fundamental_matrix_inv = exp(A*Δt)^-1

    @inbounds for i in eachindex(output_set)
        output_set[i] = fundamental_matrix_inv * output_set[i]
    end

    return ConvexSet(output_set, false, false)
end

function propagate_backward!(
    cs::ConvexSet,
    A::SMatrix,
    a_ub::Real,
    a_lb::Real,
    Δt::Real
)
    output_set = cs.vertices
    leninput = length(cs.vertices)

    # minkowski
    accelerate = -SVector{2,Float64}(a_ub / 2 * Δt^2, a_ub * Δt)
    decelerate = -SVector{2,Float64}(a_lb / 2 * Δt^2, a_lb * Δt)
    minkowski_vec = SVector{2,Float64}(-2 / Δt, 1) # rotated by 90°

    counter = 1
    previous_correction = SVector{2, Float64}(0, 0)
    first_correction = SVector{2, Float64}(0, 0)
    next_correction = SVector{2, Float64}(0, 0)

    @inbounds for i in 1:leninput
        i == leninput ? next_correction = first_correction : nothing

        vec_to_i = output_set[counter] - (cycle(output_set, counter-1) - previous_correction)
        vec_from_i = (cycle(output_set, counter+1) - next_correction) - output_set[counter]
        dot_to_i = dot(vec_to_i, minkowski_vec)
        dot_from_i = dot(vec_from_i, minkowski_vec) 
        
        if dot_to_i ≤ 0 && dot_from_i ≤ 0 
            output_set[counter] = output_set[counter] + accelerate
            previous_correction = accelerate
        elseif dot_to_i ≤ 0 && dot_from_i ≥ 0 
            orig = output_set[counter]
            output_set[counter] = orig + accelerate
            counter += 1
            insert!(output_set, counter, orig + decelerate)
            previous_correction = decelerate
        elseif dot_to_i ≥ 0 && dot_from_i ≤ 0
            orig = output_set[counter] 
            output_set[counter] = orig + decelerate
            counter += 1
            insert!(output_set, counter, orig + accelerate)
            previous_correction = accelerate
        elseif dot_to_i ≥ 0 && dot_from_i ≥ 0 
            output_set[counter] = output_set[counter] + decelerate
            previous_correction = decelerate
        end
        counter += 1

        i == 1 ? first_correction = previous_correction : nothing
    end

    # time-step backward
    fundamental_matrix_inv = exp(A*Δt)^-1

    @inbounds for i in eachindex(output_set)
        output_set[i] = fundamental_matrix_inv * output_set[i]
    end

    return nothing
end

# TODO add propagate for (initial) State