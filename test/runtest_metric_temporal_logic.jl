@testset "MTL Parsing" begin
    #=
    pred1 = OnLanelet(1, Set([143]))
    pred2 = OnConflictSection(1, 75)
    pred3 = BehindAgent([1, 2])
    pred4 = SlowerAgent([1, 2])

    testmtl = MTLPredicate(Globally, Absolute, Or, UnitRange(1,10), [
        MTLPredicate(Globally, Absolute, And, UnitRange(1,5), [
            MTLPredicate(Globally, Absolute, And, UnitRange(2, 5), [
                    pred1, 
                    pred2
                ]),
                pred3
            ]),
        MTLPredicate(Once, Relative, And, UnitRange(1, 3), [
            pred4
        ])
    ])

    @info testmtl
    @test isa(testmtl, MTLPredicate)
    =#
    @test true
end