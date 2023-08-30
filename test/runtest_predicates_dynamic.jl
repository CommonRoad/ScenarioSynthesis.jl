@testset "Dynamic Predicates" begin
    ### load LaneletNetwork
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)
    process!(ln)

    lenwid = SVector{2, Float64}(5.0, 2.2)

    ### define Agents
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

    agent_ego = Agent(route_ego, cs_ego)
    agent_other = Agent(route_other, cs_other)
    agents = AgentsDict([agent_ego, agent_other], ln)

    print(agents.offset)

    # BehindAgent
    behind_agent_predicate = BehindAgent([1, 2])
    apply_predicate!(behind_agent_predicate, agents, 1, 0.5)
    @test true # "no errors thrown so far"

    # SlowerAgent
    slower_agent_predicate = SlowerAgent([1, 2])
    apply_predicate!(slower_agent_predicate, agents, 1, 0.5)
    @test true # "no errors thrown so far"
end