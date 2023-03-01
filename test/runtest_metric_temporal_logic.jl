using ScenarioSynthesis
using Test

@testset "MTL Parsing" begin
    testmtl = MTLPredicate(Globally, Or, UnitRange(1,10), [
        MTLPredicate(Globally, And, UnitRange(1,5), [
            MTLPredicate(Globally, And, UnitRange(2, 5), Vector{BasicPredicate}()),
            #BasicPredicate(), 
            #BasicPredicate()
            ]),
        MTLPredicate(Once, And, UnitRange(1, 3), Vector{BasicPredicate}())
    ])

    @test isa(testmtl, MTLPredicate)
end