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

    conflict_sections_invert = Dict((v,k) for (k, v) in ln.conflict_sections) 
    conflict_id = conflict_sections_invert[(92, 144)]
    section92 = ln.lanelets[92].conflict_sections[conflict_id]
    section144 = ln.lanelets[144].conflict_sections[conflict_id]
    @test isapprox(section92[1], 9.167297889448239)
    @test isapprox(section92[2], 13.827340983251094)
    @test isapprox(section144[1], 5.926364934429366)
    @test isapprox(section144[2], 10.535759883429986)
end