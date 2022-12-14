using ScenarioSynthesis
using Test

@testset "Routes" begin # TODO update tests
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    @info "path: $path"
    ln = ln_from_xml(path)

    route1 = Route(LaneletID.([64, 143, 11]), ln)
    route2 = Route(LaneletID.([8, 92, 11]), ln)
    route3 = Route(LaneletID.([66, 147, 63]), ln)
    route4 = Route(LaneletID.([25, 112, 66, 146]), ln)

    @test ref_pos_of_conflicting_routes(route1, route2, ln)[2] == true
    @test ref_pos_of_conflicting_routes(route1, route3, ln)[2] == false
    @test ref_pos_of_conflicting_routes(route1, route4, ln)[2] == false
    @test ref_pos_of_conflicting_routes(route2, route3, ln)[2] == false 
    @test ref_pos_of_conflicting_routes(route2, route4, ln)[2] == false
    @test ref_pos_of_conflicting_routes(route3, route4, ln)[2] == true
end