using ScenarioSynthesis
using Test

@testset "Routes" begin # TODO update tests
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)
    process!(ln)

    route0 = Route(LaneletID.([64]), ln)
    route1 = Route(LaneletID.([64, 143, 11]), ln)
    route2 = Route(LaneletID.([8, 92, 11]), ln)
    route3 = Route(LaneletID.([66, 147, 63]), ln)
    route4 = Route(LaneletID.([25, 112, 66, 146]), ln)

    @test all(isapprox.(route1.conflict_sections[20], [127.65245723319552, 134.0724903676841])) # csid could change from time to time

    @test reference_pos(route0, route0, ln) == ([56.6951, -24.23635], [56.6951, -24.23635], true) # same lanelet
    @test reference_pos(route0, route1, ln) == ([56.6951, -24.23635], [56.6951, -24.23635], true) # same lanelet
    @test reference_pos(route1, route2, ln) == ([111.86265, -27.99525], [111.86265, -27.99525], true)
    @test reference_pos(route1, route2, ln) == reference_pos(route2, route1, ln)
    @test reference_pos(route1, route3, ln) == ([Inf, Inf], [Inf, Inf], false)
    @test reference_pos(route2, route3, ln) == ([57.34194907069542, -16.19480523769797], [57.34194907069542, -16.19480523769797], true)
end