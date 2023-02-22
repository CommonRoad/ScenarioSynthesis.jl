using ScenarioSynthesis
using Test
using StaticArrays
import ScenarioSynthesis.ActorID

@testset "Synthesis" begin
    ### load LaneletNetwork
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)
    process!(ln)
    #plot_lanelet_network(ln; annotate_id=true)

    lenwid = SVector{2, Float64}(5.0, 2.2)


    ### define Actors
    route0 = Route(LaneletID.([64]), ln, lenwid)
    route1 = Route(LaneletID.([64, 143, 11]), ln, lenwid)
    route2 = Route(LaneletID.([8, 92, 11]), ln, lenwid)
    route3 = Route(LaneletID.([66, 147, 63]), ln, lenwid)
    route4 = Route(LaneletID.([25, 112, 66, 146]), ln, lenwid)

    cs = ConvexSet([
        State(0, 0),
        State(1, 0),
        State(1, 1),
        State(0, 1),
    ])

    actor1 = Actor(route1, cs)
    actor2 = Actor(route2, cs; a_min=-2.0)
    actor3 = Actor(route3, cs)
    actor4 = Actor(route4, cs)

    actors = ActorsDict([actor1, actor2, actor3, actor4], ln)

    offset_ref = Dict{Tuple{ActorID, ActorID}, Float64}()
    offset_ref[(3, 2)] = 49.9693
    offset_ref[(1, 2)] = 14.4121
    offset_ref[(2, 1)] = -14.4121
    offset_ref[(3, 4)] = 355.585
    offset_ref[(4, 3)] = -355.585
    offset_ref[(2, 3)] = -49.9693

    for (k, v) in actors.offset
        @test isapprox(v, offset_ref[k]; atol=1e-2)
    end
end