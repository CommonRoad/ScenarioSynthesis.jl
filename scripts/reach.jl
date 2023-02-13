using ReachabilityAnalysis
using MathematicalSystems

x0 = [40.0, 28.0, 0.0]

A = [0 1 0; 0 0 1; 0 0 0]
b = [0, 0, 1]
x_lims = [-Inf Inf; -10.0 40.0; -Inf Inf]
u_lims = [-Inf Inf; -Inf Inf; -7.0 3.0]

model = ConstrainedLinearControlContinuousSystem(A, b[:,:], x_lims, u_lims)
model = LinearControlContinuousSystem(A, b[:,:])

normalize(model)

prob = @ivp(model, x(0) ∈ x0, dim=3)

solve(prob, NSTEPS=20)

struct State
    vel::Float64
    pos::Float64
end

struct LinearModel
    a_max::Float64
    a_min::Float64
end

function propagate(state::State, model::LinearModel, Δt::Number)
    state_max = State(state.vel + model.a_max * Δt, state.pos + state.vel * Δt + model.a_max/2 * Δt)
    state_min = State(state.vel + model.a_min * Δt, state.pos + state.vel * Δt + model.a_min/2 * Δt)
    return state_max, state_min
end

st1 = State(15, 0)
st2 = State(15, 10)
st3 = State(20, 10)
st4 = State(20, 0)

x0 = [st1 st2; st3 st4]

function propagate(state_matrix::Matrix{State}, model::LinearModel, Δt::Number)
    n, m = size(state_matrix)
    n == 2 || throw(error("state matrix must have exactly 2 rows.")) # TODO maybe change as mat[:,i] allows faster access
    result = Matrix{State}(undef, n, m+1)
    
    return 
end


### Prototyping

using BenchmarkTools
using StaticArrays
using DataStructures
using LinearAlgebra

A = [0.0 1.0; 0.0 0.0]
Δt = 0.2
fund = exp(A*Δt)

st1 = [0.0; 2.0]
st2 = [0.0; 4.0]
st3 = [10.0; 4.0]
st4 = [10.0; 2.0]

states = [st1 st2 st3 st4]

@benchmark $fund*$states

fund_stat = SMatrix{2,2,Float64,4}(fund...)
states_stat = SMatrix{2,4,Float64,8}(states...)

@benchmark $fund_stat*$states_stat

states_mixed = SVector{2,Float64}.([st1, st2, st3, st4])
@benchmark [$fund_stat*st for st in $states_mixed]

states_cb = CircularBuffer{SVector{2,Float64}}(4)

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
"""
function propagate(convex_states::Vector, a_max::Real, a_min::Real, Δt::Real) # TODO constructor for convex states
    accelerate = SVector{2,Float64}(a_max / 2 * Δt^2, a_max * Δt)
    decelerate = SVector{2,Float64}(a_min / 2 * Δt^2, a_min * Δt)
    vec_to_next = diff(convex_states)
    pushfirst!(vec_to_next, convex_states[1] - convex_states[end]) # closed shape

    ref_gain = SVector{2,Float64}(-2 / Δt, 1) # rotated by 90°
    dotprod = map(x -> dot(x, ref_gain), vec_to_next)

    # bei VZ wechsel acc + dec
    propagated_states = Vector{SVector{2, Float64}}()
    sizehint!(propagated_states, length(convex_states)+2) # can reduce allocs
    for i in eachindex(convex_states)
        if dotprod[i] ≤ 0 && cycle(dotprod, i+1) ≤ 0 
            push!(propagated_states, convex_states[i] + decelerate)
        elseif dotprod[i] ≤ 0 && cycle(dotprod, i+1) ≥ 0 
            push!(propagated_states, convex_states[i] + decelerate)
            push!(propagated_states, convex_states[i] + accelerate)
        elseif dotprod[i] ≥ 0 && cycle(dotprod, i+1) ≤ 0 
            push!(propagated_states, convex_states[i] + accelerate)
            push!(propagated_states, convex_states[i] + decelerate)
        else # dotprod[i] ≥ 0 && cycle(dotprod, i+1) ≥ 0 
            push!(propagated_states, convex_states[i] + accelerate)
        end
    end

    return propagated_states # convex_states # dotprod
end

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