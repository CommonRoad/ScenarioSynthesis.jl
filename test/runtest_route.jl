using ScenarioSynthesis
using Test
using StaticArrays

@testset "Corner Cutting" begin
    ls = [Pos(FCart, 2*i, 4*sin(i)) for i=1:20]
    ls = corner_cutting(ls, 1)
    @test length(ls) == 38
    @test isa(ls, Vector{Pos{FCart}})
end

@testset "Routes" begin # TODO update tests
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)
    process!(ln)

    lenwid = SVector{2, Float64}(5.0, 2.2)

    route0 = Route(LaneletID.([64]), ln, lenwid)
    route1 = Route(LaneletID.([64, 143, 11]), ln, lenwid)
    route2 = Route(LaneletID.([8, 92, 11]), ln, lenwid)
    route3 = Route(LaneletID.([66, 147, 63]), ln, lenwid)
    route4 = Route(LaneletID.([25, 112, 66, 146]), ln, lenwid)

    print(route1.conflict_sections[20])
    @test all(isapprox.(route1.conflict_sections[20], [127.57066556122432, 133.92983221345858])) # csid could change from time to time

    @test reference_pos(route0, route0, ln) == ([-6.1858, -126.32625], [-6.1858, -126.32625], true) # same lanelet
    @test reference_pos(route0, route1, ln) == ([-6.1858, -126.32625], [-6.1858, -126.32625], true) # same lanelet
    @test reference_pos(route1, route2, ln) == ([68.68379999999999, -18.79935], [68.68379999999999, -18.79935], true) # merging routes
    @test reference_pos(route1, route2, ln) == reference_pos(route2, route1, ln)
    @test reference_pos(route1, route3, ln) == ([Inf, Inf], [Inf, Inf], false) # no intersection
    @test reference_pos(route2, route3, ln) == ([57.34194907069542, -16.19480523769797], [57.34194907069542, -16.19480523769797], true) # intersection
    # TODO test neighboring lanelets, diverging route

    # TODO test LaneletIntervals
end