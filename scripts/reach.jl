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

cs = ConvexSet([
    State(0, 0), 
    State(1, 0), 
    State(1, 1), 
    State(0, 1), 
])

plot(cs)
area(states)

@benchmark area($states)

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
upper_lim!(states, 1, 5.0)
plot!(states)
lower_lim!(states, 2, -1.0)
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
], false, false)) evals=1

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
], false, false)) evals=1


@benchmark upper_lim!(states, 1, 4.0) setup=(states = ConvexSet([
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
], false, false)) evals=1

#### Profiling
using Profile
function foo(num::Integer)
    A = SMatrix{2, 2, Float64, 4}(0, 0, 1, 0)
    Δt = 0.2
    for i=1:num
        cs = ConvexSet([
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
        ], false, false)

        propagate!(cs, A, 4.0,-8.0, Δt)
    end
end

@profview foo(1000000)

#### Vehicles 
# initial states
vehicle1 = ConvexSet([
    SVector{2, Float64}(2,1),
    SVector{2, Float64}(4,1),
    SVector{2, Float64}(4,3),
    SVector{2, Float64}(2,3),
])

vehicle2 = ConvexSet([
    SVector{2, Float64}(3,2),
    SVector{2, Float64}(5,2),
    SVector{2, Float64}(5,4),
    SVector{2, Float64}(3,4),
])

plot(vehicle1)
plot!(vehicle2)

@benchmark intersection($vehicle1, $vehicle2)

function ffo(num, cs1, cs2)
    for i=1:num
        cs3 = intersection(cs1, cs2)
    end
    return nothing
end

@profview ffo(1000000, vehicle1, vehicle2)

# traffic rules + specifications to be considered
# v1 keeps lane speed limit (10 m/s)
# v1 is behind v2 || v1 is slower v2 

upper_lim!(vehicle1, 1, 10.0)

vehicle1_fork = copy(vehicle1)

pos_lim = get_upper_lim(vehicle2, 1, 0.6)
vel_lim = get_upper_lim(vehicle2, 2, 0.8)
upper_lim!(vehicle1, 1, pos_lim)
upper_lim!(vehicle1_fork, 2, vel_lim)
plot!(vehicle1)
plot!(vehicle1_fork)

struct Intersect end
struct Vertice end

function foo(::Type{Intersect}, a::Real)
    print("this function handels type intersect")
end