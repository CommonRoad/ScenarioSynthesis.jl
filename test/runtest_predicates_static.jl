using ScenarioSynthesis
using Test
using StaticArrays

@testset "OnLanelet Predicate" begin
    ### load LaneletNetwork
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)
    process!(ln)

    lenwid = SVector{2, Float64}(5.0, 2.2)

    ### define Actors
    route_ego = Route(LaneletID.([64, 143, 11]), ln, lenwid)

    cs = ConvexSet([
        State(110, 0),
        State(140, 0),
        State(140, 10),
        State(110, 10),
    ])

    actor_ego = Actor(route_ego, cs)
    actors_dict = ActorsDict([actor_ego], ln)

    predicate = OnLanelet(1, Set([143]))

    bounds = Bounds(predicate, actors_dict)

    @test bounds.s_lb == actor_ego.route.lanelet_interval[143].lb
    @test bounds.s_ub == actor_ego.route.lanelet_interval[143].ub
end