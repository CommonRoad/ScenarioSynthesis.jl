import Gurobi: Env

@testset "Predicates multi agent" begin
    ### load LaneletNetwork
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)
    process!(ln)

    lenwid = SVector{2, Float64}(5.0, 2.2)

    ### define Agents
    route_ego = Route(LaneletID.([64, 143, 11]), ln, lenwid)
    route_other = Route(LaneletID.([64, 143, 11]), ln, lenwid)

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

    # print(agents.offset)

    # SlowerAgent
    slower_agent_predicate = SlowerAgent([1, 2])
    apply_predicate!(slower_agent_predicate, agents, 1)
    @test max(agent_ego.states[1], 2) == 14
    @test min(agent_other.states[1], 2) == 14

    # BehindAgent
    behind_agent_predicate = BehindAgent([1, 2])
    apply_predicate!(behind_agent_predicate, agents, 1)
    @test max(agent_ego.states[1], 1) == 57.5
    @test min(agent_other.states[1], 1) == 62.5

    # SafeDistance
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

    agent_ego = Agent(route_ego, cs_ego; a_lb=-4.0)
    agent_other = Agent(route_other, cs_other; a_lb=-8.0)
    agents = AgentsDict([agent_ego, agent_other], ln)
    
    grb_env = Env()
    safe_distance_predicate = SafeDistance([1, 2])
    apply_predicate!(safe_distance_predicate, agents, 1)
    #display(plot(plot_data(agents.agents[1].states[1])))
    #@test isequal(agent_ego.states[1], ConvexSet([40 57.5 57.5 55.21875000000002 49.87500000000001 45.9375 40; 12 12 12.784313725490197 13.499999999999995 14.999999999999998 16 16]))
    #@test isequal(agent_other.states[1], ConvexSet([73.84240235004168 80 80 67.78294249596826; 12 12 16 16]))
end