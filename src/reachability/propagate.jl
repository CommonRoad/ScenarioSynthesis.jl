"""
    propagate

Assumptions: 
- constant acceleration inbetween time-steps. 
- input set must be convex. 
- A linear system model (state space)
"""
function propagate(
    cs::ConvexStates, 
    A::SMatrix, 
    a_max::Real, 
    a_min::Real, 
    Δt::Real
)
    input_set = copy(cs.vertices)

    # time-step forward
    fundamental_matrix = exp(A*Δt)
    @inbounds for i in eachindex(input_set)
        input_set[i] = fundamental_matrix * input_set[i]
    end

    # minkowski
    accelerate = SVector{2,Float64}(a_max / 2 * Δt^2, a_max * Δt)
    decelerate = SVector{2,Float64}(a_min / 2 * Δt^2, a_min * Δt)
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
        else # dot_to_i ≥ 0 && dot_from_i ≥ 0 
            output_set[counter] = input_set[i] + accelerate
        end
        counter += 1
    end

    return ConvexStates(output_set, false)
end

function propagate!(
    cs::ConvexStates, 
    A::SMatrix, 
    a_max::Real, 
    a_min::Real, 
    Δt::Real
)
    output_set = cs.vertices
    input_set = copy(cs.vertices)

    # time-step forward
    fundamental_matrix = exp(A*Δt)
    @inbounds for i in eachindex(input_set)
        input_set[i] = fundamental_matrix * input_set[i]
    end

    # minkowski
    accelerate = SVector{2,Float64}(a_max / 2 * Δt^2, a_max * Δt)
    decelerate = SVector{2,Float64}(a_min / 2 * Δt^2, a_min * Δt)
    minkowski_vec = SVector{2,Float64}(-2 / Δt, 1) # rotated by 90°

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
            insert!(output_set, counter, input_set[i] + accelerate)
        elseif dot_to_i ≥ 0 && dot_from_i ≤ 0 
            output_set[counter] = input_set[i] + accelerate
            counter += 1
            insert!(output_set, counter, input_set[i] + decelerate)
        else # dot_to_i ≥ 0 && dot_from_i ≥ 0 
            output_set[counter] = input_set[i] + accelerate
        end
        counter += 1
    end

    return nothing
end

"""
    backwards

"""
function propagate_backwards(
    cs::ConvexStates,
    A::SMatrix,
    a_max::Real,
    a_min::Real,
    Δt::Real
)
    input_set = cs.vertices

    # minkowski
    accelerate = -SVector{2,Float64}(a_max / 2 * Δt^2, a_max * Δt)
    decelerate = -SVector{2,Float64}(a_min / 2 * Δt^2, a_min * Δt)
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
        else # dot_to_i ≥ 0 && dot_from_i ≥ 0 
            output_set[counter] = input_set[i] + decelerate
        end
        counter += 1
    end

    # time-step backward
    fundamental_matrix_inv = exp(A*Δt)^-1

    @inbounds for i in eachindex(output_set)
        output_set[i] = fundamental_matrix_inv * output_set[i]
    end

    return ConvexStates(output_set, false)
end

function propagate_backwards!(
    cs::ConvexStates,
    A::SMatrix,
    a_max::Real,
    a_min::Real,
    Δt::Real
)
    output_set = cs.vertices
    input_set = copy(cs.vertices)

    # minkowski
    accelerate = -SVector{2,Float64}(a_max / 2 * Δt^2, a_max * Δt)
    decelerate = -SVector{2,Float64}(a_min / 2 * Δt^2, a_min * Δt)
    minkowski_vec = SVector{2,Float64}(-2 / Δt, 1) # rotated by 90°

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
            insert!(output_set, counter, input_set[i] + decelerate)
        elseif dot_to_i ≥ 0 && dot_from_i ≤ 0 
            output_set[counter] = input_set[i] + decelerate
            counter += 1
            insert!(output_set, counter, input_set[i] + accelerate)
        else # dot_to_i ≥ 0 && dot_from_i ≥ 0 
            output_set[counter] = input_set[i] + decelerate
        end
        counter += 1
    end

    # time-step backward
    fundamental_matrix_inv = exp(A*Δt)^-1

    @inbounds for i in eachindex(output_set)
        output_set[i] = fundamental_matrix_inv * output_set[i]
    end

    return nothing
end