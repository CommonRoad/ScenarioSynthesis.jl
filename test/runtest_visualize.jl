using ScenarioSynthesis
using Test
using StaticArrays
import Plots

@testset "plots" begin
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)
    process!(ln)

    p_lt = plot_lanelet(ln.lanelets[64], 64)
    @test isa(p_lt, Plots.Plot)

    p_ln = plot_lanelet_network(ln)
    @test isa(p_ln, Plots.Plot)

    p_po = plot_polygon(Polygon(FCart, [1 2 3; 4 5 6]))
    @test isa(p_po, Plots.Plot)

    lenwid = SVector{2, Float64}(5.0, 2.2)
    route = Route(LaneletID.([64]), ln, lenwid)
    p_ro = plot_route(route)
    @test isa(p_ro, Plots.Plot)
end