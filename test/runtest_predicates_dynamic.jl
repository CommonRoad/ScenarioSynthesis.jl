using ScenarioSynthesis
using Test
using StaticArrays

@testset "Dynamic Predicates" begin
    ### load LaneletNetwork
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)
    process!(ln)
    plot_lanelet_network(ln; annotate_id=true)

    lenwid = SVector{2, Float64}(5.0, 2.2)

    ### define Actors
    route_ego = Route(LaneletID.([64, 143, 11]), ln, lenwid)
    route_other = Route(LaneletID.([8, 92, 11]), ln, lenwid)

    cs = ConvexSet([
        State(0, 0),
        State(1, 0),
        State(1, 1),
        State(0, 1),
    ])

    actor_ego = Actor(route_ego, cs)
    actor_other = Actor(route_other, cs)
    actors = ActorsDict([actor_ego, actor_other], ln)

    # BehindActor
    behind_actor_predicate = BehindActor(1, 2)
    behind_actor_bounds = Bounds(behind_actor_predicate, actors, 1, 1.0)
    @test behind_actor_bounds.s_lb == -Inf
    @test isapprox(behind_actor_bounds.s_ub, -19.412124882931153)

    behind_actor_bounds_relaxed = Bounds(behind_actor_predicate, actors, 1, 0.6)
    @test behind_actor_bounds_relaxed.s_ub > behind_actor_bounds.s_ub

    # SlowerActor
    slower_actor_predicate = SlowerActor(1, 2)
    slower_actor_bounds = Bounds(slower_actor_predicate, actors, 1, 1.0)
    @test slower_actor_bounds.v_lb == -Inf
    @test isapprox(slower_actor_bounds.v_ub, 0.0)

    slower_actor_bounds_relaxed = Bounds(slower_actor_predicate, actors, 1, 0.6)
    @test slower_actor_bounds_relaxed.v_ub > slower_actor_bounds.v_ub
end