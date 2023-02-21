using ScenarioSynthesis
using Test

@testset "Synthesis" begin
    ### load LaneletNetwork
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)
    process!(ln)
    #plot_lanelet_network(ln; annotate_id=true)


    ### define Actors
    route0 = Route(LaneletID.([64]), ln);
    route1 = Route(LaneletID.([64, 143, 11]), ln);
    route2 = Route(LaneletID.([8, 92, 11]), ln);
    route3 = Route(LaneletID.([66, 147, 63]), ln);
    route4 = Route(LaneletID.([25, 112, 66, 146]), ln);

    cs = ConvexSet([
        State(0, 0),
        State(1, 0),
        State(1, 1),
        State(0, 1),
    ])

    actor1 = Actor(route1, cs);
    actor2 = Actor(route2, cs; a_min=-2.0);
    actor3 = Actor(route3, cs);
    actor4 = Actor(route4, cs);

    @test lanelets(actor1, ln, 80.0, 20.0, 1.0, -0.4) == Set([63, 64])
    @test lanelets(actor1, ln, 80.0, 20.0, 0.0, -0.4) == Set([64])
    @test lanelets(actor1, ln, 0.0, 20.0, 0.0, -0.4) == Set([64, 138])
    @test lanelets(actor1, ln, 0.0, 20.0, 2.0, -0.4) == Set([64, 138, 63, 141])

    actors = ActorsDict([actor1, actor2, actor3, actor4], ln);

    @test lanelets(actor1, ln, 119.0, 10.0, 2.0, 0.2) == Set([93, 64, 63, 147, 91, 144, 142, 143])
    @test lanelets(actor1, ln, 120.0, 10.0, 2.0, 0.2) == Set([93, 64, 63, 144, 142, 143]) # maybe enhance calculation even more...
end