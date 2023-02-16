using ScenarioSynthesis
using StaticArrays
using BenchmarkTools

# inits
states = ConvexSet([
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

# propagation
plot!(states)
states_forward = propagate(states, A, 4.0, -8.0, Δt)
states_backward = propagate_backward(states, A, 4.0, -8.0, Δt)
plot!(states_forward)
plot!(states_backward)
propagate!(states, A, 4.0,-8.0, Δt)
propagate_backward!(states, A, 4.0,-8.0, Δt)

# limits
plot(states)
upper_lim!(states, 5.0, 1)
plot!(states)
lower_lim!(states, -1.0, 2)
plot!(states)

# benchmarks
@benchmark propagate($states, $A, 4.0, -8.0, $Δt)
@benchmark propagate_backward($states, $A, 4.0, -8.0, $Δt)

@benchmark propagate!(states, $A, 4.0, -8.0, $Δt) setup=(states = ConvexSet([
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

@benchmark propagate_backward!(states, $A, 4.0, -8.0, $Δt) setup=(states = ConvexSet([
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


@benchmark upper_lim!(states, 4.0, 1) setup=(states = ConvexSet([
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