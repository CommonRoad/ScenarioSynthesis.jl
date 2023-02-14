### Prototyping

using BenchmarkTools
using StaticArrays
using DataStructures
using LinearAlgebra
using Plots

struct ConvexPolygon
    vertices::Vector{SVector{2, Float64}} # SVector => State? 

    function ConvexPolygon(vertices::Vector{SVector{2, Float64}}, checkConvexity::Bool=true)
        checkConvexity && is_convex(vertices) || throw(error("Vertices are non-convex."))
        return new(vertices)
    end
end

function is_convex(vertices::Vector{SVector{2, Float64}})
    return true # TODO add code
end

states = [
    SVector{2,Float64}(0,0),
    SVector{2,Float64}(1,-2),
    SVector{2,Float64}(3,-3),
    SVector{2,Float64}(5,-3),
    SVector{2,Float64}(7,-2),
    SVector{2,Float64}(8,0),
    SVector{2,Float64}(8,2),
    SVector{2,Float64}(7,4),
    SVector{2,Float64}(5,5),
    SVector{2,Float64}(3,5),
    SVector{2,Float64}(1,4),
    SVector{2,Float64}(0,2),
]

A = SMatrix{2, 2, Float64, 4}(0, 0, 1, 0)
Δt = 0.2

@inline function cycle(vec::Vector, ind::Integer)
    lenvec = length(vec)
    ind = mod(ind, 1:lenvec)
    return vec[ind]
end


"""
    propagate

Assumptions: 
- constant acceleration inbetween time-steps. 
- input set must be convex. 
- A linear system model (state space)
"""
function propagate(convex_states::Vector{<:SVector}, A::SMatrix, a_max::Real, a_min::Real, Δt::Real) # TODO constructor for convex states, 
    accelerate = SVector{2,Float64}(a_max / 2 * Δt^2, a_max * Δt)
    decelerate = SVector{2,Float64}(a_min / 2 * Δt^2, a_min * Δt)
    fundamental_matrix = exp(A*Δt)
    steady_states = [fundamental_matrix * x for x in convex_states]
    vec_to_next = diff(steady_states)
    pushfirst!(vec_to_next, steady_states[1] - steady_states[end]) # closed shape

    minkowski_gain = SVector{2,Float64}(-2 / Δt, 1) # rotated by 90°
    dotprod = map(x -> dot(x, minkowski_gain), vec_to_next)

    propagated_states = Vector{SVector{2, Float64}}()
    sizehint!(propagated_states, length(steady_states)+2) # can reduce allocs
    for i in eachindex(steady_states)
        if dotprod[i] ≤ 0 && cycle(dotprod, i+1) ≤ 0 
            push!(propagated_states, steady_states[i] + decelerate)
        elseif dotprod[i] ≤ 0 && cycle(dotprod, i+1) ≥ 0 
            push!(propagated_states, steady_states[i] + decelerate)
            push!(propagated_states, steady_states[i] + accelerate)
        elseif dotprod[i] ≥ 0 && cycle(dotprod, i+1) ≤ 0 
            push!(propagated_states, steady_states[i] + accelerate)
            push!(propagated_states, steady_states[i] + decelerate)
        else # dotprod[i] ≥ 0 && cycle(dotprod, i+1) ≥ 0 
            push!(propagated_states, steady_states[i] + accelerate)
        end
    end

    return propagated_states
end

function propagate!(convex_states::Vector{<:SVector}, A::SMatrix, a_max::Real, a_min::Real, Δt::Real)
    lencon = length(convex_states)
    accelerate = SVector{2,Float64}(a_max / 2 * Δt^2, a_max * Δt)
    decelerate = SVector{2,Float64}(a_min / 2 * Δt^2, a_min * Δt)
    fundamental_matrix = exp(A*Δt) # TODO maybe outsource (repetitive) ? 
    @inbounds for i in eachindex(convex_states)
        convex_states[i] = fundamental_matrix * convex_states[i]
    end
    
    # TODO maybe implement without diff, map to minimize allocs? 
    vec_to_next = diff(convex_states)
    pushfirst!(vec_to_next, convex_states[1] - convex_states[end])

    minkowski_gain = SVector{2,Float64}(-2 / Δt, 1) # rotated by 90°
    dotprod = map(x -> dot(x, minkowski_gain), vec_to_next)

    counter = 1
    @inbounds for i in 1:lencon
        state_orig = convex_states[counter]
        if dotprod[i] ≤ 0 && cycle(dotprod, i+1) ≤ 0 
            convex_states[counter] = state_orig + decelerate
        elseif dotprod[i] ≤ 0 && cycle(dotprod, i+1) ≥ 0 
            convex_states[counter] = state_orig + decelerate
            insert!(convex_states, counter+1, state_orig + accelerate)
            counter += 1
        elseif dotprod[i] ≥ 0 && cycle(dotprod, i+1) ≤ 0 
            convex_states[counter] = state_orig + accelerate
            insert!(convex_states, counter+1, state_orig + decelerate)
            counter += 1
        else # dotprod[i] ≥ 0 && cycle(dotprod, i+1) ≥ 0 
            convex_states[counter] = state_orig + accelerate
        end
        counter += 1
    end

    return nothing
end

@benchmark propagate!(states, $A, 4.0, -8.0, 0.2) setup=(states = [
    SVector{2,Float64}(0,0),
    SVector{2,Float64}(1,-2),
    SVector{2,Float64}(3,-3),
    SVector{2,Float64}(5,-3),
    SVector{2,Float64}(7,-2),
    SVector{2,Float64}(8,0),
    SVector{2,Float64}(8,2),
    SVector{2,Float64}(7,4),
    SVector{2,Float64}(5,5),
    SVector{2,Float64}(3,5),
    SVector{2,Float64}(1,4),
    SVector{2,Float64}(0,2),
]) evals=1

plot(hcat(states...)[1,:], hcat(states...)[2,:]; aspect_ratio=:equal)
propagate!(states, A, 4.0, -8.0, 0.2); plot!(hcat(states...)[1,:], hcat(states...)[2,:]; aspect_ratio=:equal)

## set vs. Vector{Bool} vs. BitVector

using DataStructures

set_a = Set(round.(Int, 20000*rand(10000)))
set_b = Set(round.(Int, 20000*rand(10000)))

@benchmark setdiff($set_a, $set_b)
@benchmark union($set_a, $set_b)

bool_a = rand(Bool, 10000)
bool_b = rand(Bool, 10000)
bit_a = BitVector(bool_a)
bit_b = BitVector(bool_b)

@benchmark $bool_a.&&$bool_b
@benchmark $bool_a.||$bool_b

@benchmark $bit_a.&&$bit_b
@benchmark $bit_a.||$bit_b