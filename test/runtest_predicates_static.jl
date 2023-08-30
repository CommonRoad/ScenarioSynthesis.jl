using ScenarioSynthesis
using Test
using StaticArrays

@testset "Static Predicate" begin
    ### load LaneletNetwork
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)
    process!(ln)

    lenwid = SVector{2, Float64}(5.0, 2.2)

    ### define Agents
    route_ego = Route(LaneletID.([64, 143, 11]), ln, lenwid)

    cs = ConvexSet([
        State(110, 0),
        State(140, 0),
        State(140, 10),
        State(110, 10),
    ])

    agent_ego = Agent(route_ego, cs)
    agents_dict = AgentsDict([agent_ego], ln)

    # OnLanelet
    on_lanelet_predicate = OnLanelet(1, Set([143]))
    on_lanelet_bounds = Bounds(on_lanelet_predicate, agents_dict)
    @test on_lanelet_bounds.s_lb == agent_ego.route.lanelet_interval[143].lb
    @test on_lanelet_bounds.s_ub == agent_ego.route.lanelet_interval[143].ub

    # OnConflictSection
    #=
    on_conflict_section_predicate = OnConflictSection(1, 75)
    on_conflict_section_bounds = Bounds(on_conflict_section_predicate, agents_dict)
    @test on_conflict_section_bounds.s_lb == agent_ego.route.conflict_sections[75][1]
    @test on_conflict_section_bounds.s_ub == agent_ego.route.conflict_sections[75][2]

    # BeforeConflictSection
    before_conflict_section_predicate = BeforeConflictSection(1, 75)
    before_conflict_section_bounds = Bounds(before_conflict_section_predicate, agents_dict)
    @test before_conflict_section_bounds.s_lb == -Inf
    @test before_conflict_section_bounds.s_ub == agent_ego.route.conflict_sections[75][1]

    # BehindConflictSection
    behind_conflict_section_predicate = BehindConflictSection(1, 75)
    behind_conflict_section_bounds = Bounds(behind_conflict_section_predicate, agents_dict)
    @test behind_conflict_section_bounds.s_lb == agent_ego.route.conflict_sections[75][2]
    @test behind_conflict_section_bounds.s_ub == Inf
    =#
end