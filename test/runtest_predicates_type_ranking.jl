@testset "Predicate type ranking" begin
    predicates = [
        SafeDistance([2, 3]),
        BehindAgent([1, 2]),
        SlowerAgent([2, 1]),
        OnLanelet(1, Set([1])),
        BehindConflictSection(1, 2)
    ]
    sort!(predicates, lt=type_ranking)
    @test typeof(predicates[1]) <: PredicateSingle
    @test typeof(predicates[2]) <: PredicateSingle
    @test typeof(predicates[3]) == SlowerAgent
    @test typeof(predicates[4]) == BehindAgent
    @test typeof(predicates[5]) == SafeDistance
end