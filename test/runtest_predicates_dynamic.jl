using ScenarioSynthesis
using Test
using StaticArrays

@testset "Dynamic Predicates" begin
    ### load LaneletNetwork
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)
    process!(ln)

    lenwid = SVector{2, Float64}(5.0, 2.2)

    ### define Actors
    route_ego = Route(LaneletID.([64, 143, 11]), ln, lenwid)
    route_other = Route(LaneletID.([8, 92, 11]), ln, lenwid)

    cs_ego = ConvexSet([
        State(40, 12),
        State(80, 12),
        State(80, 16),
        State(40, 16),
    ])

    cs_other = ConvexSet([
        State(40, 12),
        State(80, 12),
        State(80, 16),
        State(40, 16),
    ])

    actor_ego = Actor(route_ego, cs_ego)
    actor_other = Actor(route_other, cs_other)
    actors = ActorsDict([actor_ego, actor_other], ln)

    print(actors.offset)

    # BehindActor
    behind_actor_predicate = BehindActor([1, 2])
    apply_predicate!(behind_actor_predicate, actors, 1, 0.5)
    @test true # "no errors thrown so far"

    # SlowerActor
    slower_actor_predicate = SlowerActor([1, 2])
    apply_predicate!(slower_actor_predicate, actors, 1, 0.5)
    @test true # "no errors thrown so far"
end