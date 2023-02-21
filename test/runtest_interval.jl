using ScenarioSynthesis
using Test

@testset "Interval" begin
    @test isa(Interval(2.0, 3.0), Interval)
    @test_throws ErrorException("empty interval.") Interval(3.0, 2.0)
end