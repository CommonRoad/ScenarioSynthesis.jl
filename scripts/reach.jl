using ScenarioSynthesis
using StaticArrays
using BenchmarkTools

states = ConvexStates([
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
])

A = SMatrix{2, 2, Float64, 4}(0, 0, 1, 0)
Δt = 0.2

@benchmark propagate!(states, $A, 4.0, -8.0, $Δt) setup=(states = ConvexStates([
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
], false)) evals=1

plot(states)
upper_lim!(states, 5.0, 1)
plot!(states)
lower_lim!(states, 2.0, 1)
plot!(states)

@benchmark upper_lim!(states, 4.0, 1) setup=(states = ConvexStates([
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
], false)) evals=1


function find_min(states, dir) # ~ 2x faster compared to standard implementation
    x = Inf
    ind = 0
    @inbounds for i in eachindex(states)
        if states[i][dir] < x
            x = states[i][dir]
            ind = i
        end
    end
    return ind
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