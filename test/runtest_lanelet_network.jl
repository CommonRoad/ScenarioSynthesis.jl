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

    #=
    conflict_sections_invert = Dict((v,k) for (k, v) in ln.conflict_sections) 
    conflict_id = conflict_sections_invert[(92, 144)]
    section92 = ln.lanelets[92].conflict_sections[conflict_id]
    section144 = ln.lanelets[144].conflict_sections[conflict_id]
    @test isapprox(section92[1], 9.167297889448239)
    @test isapprox(section92[2], 13.826340983251095)
    @test isapprox(section144[1], 5.926364934429366)
    @test isapprox(section144[2], 10.534759883429986)
    =#
end

@testset "ln functions" begin
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)

    @test Θₗ(ln.lanelets[25], 12.0) == -0.1177872951478107
    @test Θₗ(ln.lanelets[26], 12.0) == 2.8511800632458955
end

@testset "ln interstate" begin
    path = joinpath(@__DIR__, "..", "example_files", "USA_US101-10_5_T-1.xml")
    ln = ln_from_xml(path)

    process!(ln)
    @test isa(ln, LaneletNetwork)
    # TODO add more tests
end