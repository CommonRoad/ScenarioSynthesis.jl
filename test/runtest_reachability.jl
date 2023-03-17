using ScenarioSynthesis
using Test
using StaticArrays
using Plots

states_ref = ConvexSet([
    State(0,0),
    State(1,-2),
    State(3,-3),
    State(5,-3),
    State(7,-2),
    State(8,0),
    State(8,2),
    State(7,4),
    State(5,5),
    State(3,5),
    State(1,4),
    State(0,2)]
)

states_ref_forward = ConvexSet(
    [
        State(0.08000000000000002, 0.8),
        State(-0.16000000000000003, -1.6),
        State(0.43999999999999995, -3.6),
        State(2.2399999999999998, -4.6),
        State(4.24, -4.6),
        State(6.4399999999999995, -3.6),
        State(7.84, -1.6),
        State(8.24, 0.3999999999999999),
        State(8.48, 2.8),
        State(7.88, 4.8),
        State(6.08, 5.8),
        State(4.08, 5.8),
        State(1.8800000000000001, 4.8),
        State(0.48000000000000004, 2.8)
    ], 
    false, 
    false
) 

states_ref_backward = ConvexSet(
    [
        State(0.08, -0.8),
        State(1.48, -2.8),
        State(3.6799999999999997, -3.8),
        State(5.68, -3.8),
        State(7.4799999999999995, -2.8),
        State(8.08, -0.8),
        State(7.84, 1.6),
        State(7.44, 3.6),
        State(6.04, 5.6),
        State(3.8400000000000003, 6.6),
        State(1.84, 6.6),
        State(0.040000000000000153, 5.6),
        State(-0.56, 3.6),
        State(-0.32, 1.2)
    ],
    false,
    false
)

A = SMatrix{2, 2, Float64, 4}(0, 0, 1, 0)
Δt = 0.2
a_max = 4.0
a_min = -8.0

@testset "area" begin
    @test area(states_ref) == 52.0
end

@testset "centroid" begin
    @test isapprox(centroid(states_ref), State(4, 1))
end

@testset "centroid and direction" begin    
    @test true # TODO add tests
end

@testset "propagate" begin
    states_forward = propagate(states_ref, A, a_max, a_min, Δt)
    @test isapprox(states_forward.vertices, states_ref_forward.vertices)
    states = copy(states_ref)
    propagate!(states, A, a_max, a_min, Δt)
    @test isapprox(states.vertices, states_ref_forward.vertices)
end

@testset "propagate backward" begin
    states_backward = propagate_backward(states_ref, A, a_max, a_min, Δt)
    @test isapprox(states_backward.vertices, states_ref_backward.vertices)
    states = copy(states_ref)
    propagate_backward!(states, A, a_max, a_min, Δt)
    @test isapprox(states.vertices, states_ref_backward.vertices)
end

@testset "visualization" begin 
    p = plot(states_ref)
    @test isa(p, Plots.Plot)
    p = plot!(states_ref)
    @test isa(p, Plots.Plot)
end

cs1 = ConvexSet(
    [
        State(2, 1),
        State(4, 1),
        State(4, 3),
        State(2, 3)
    ]
)

cs2 = ConvexSet(
    [
        State(3, 2),
        State(5, 2),
        State(5, 4),
        State(3, 4)
    ]
)

cs3 = ConvexSet(
    [
        State(3, 0),
        State(5, 0),
        State(5, 2),
        State(3, 2)
    ]
)

cs4 = ConvexSet(
    [
        State(5, 1),
        State(5, 0),
        State(6, 0)
    ]
)

cs5_ref = ConvexSet(
    [
        State(4, 2),
        State(4, 3),
        State(3, 3),
        State(3, 2)
    ]
)

@testset "intersection" begin
    cs5 = intersection(cs1, cs2)
    @test isapprox(cs5.vertices, cs5_ref.vertices)

    @test intersection(cs1, cs4).is_empty == true
    
    @test intersection(cs2, cs3).is_empty == true
end

cs1_ub_ref = ConvexSet(
    [
        State(2.0, 1.0),
        State(3.0, 1.0),
        State(3.0, 3.0),
        State(2.0, 3.0)
    ]
)

cs1_lb_ref = ConvexSet(
    [
        State(3.0, 1.0),
        State(4.0, 1.0),
        State(4.0, 3.0),
        State(3.0, 3.0)
    ]
)

@testset "lims" begin
    @test get_upper_lim(cs2, 1, 0.25) == 4.5
    @test get_lower_lim(cs2, 1, 0.25) == 3.5

    cs1_ub = copy(cs1)
    cs1_lb = copy(cs1)

    upper_lim!(cs1_ub, 1, 3.0)
    lower_lim!(cs1_lb, 1, 3.0)

    @test isapprox(cs1_ub.vertices, cs1_ub_ref.vertices)
    @test isapprox(cs1_lb.vertices, cs1_lb_ref.vertices)
end