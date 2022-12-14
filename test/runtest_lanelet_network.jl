using ScenarioSynthesis
using Test

@testset "xml import" begin
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    @info "path: $path"
    ln = ln_from_xml(path)

    @test typeof(ln) == LaneletNetwork
end

@testset "ln processing" begin
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)

    process!(ln)

    @test ln.lanelets[92].merging_with == Set([143, 145])
    @test ln.lanelets[92].diverging_with == Set([90, 91])
    @test ln.lanelets[92].intersecting_with == Set([93, 142, 144, 147])
end