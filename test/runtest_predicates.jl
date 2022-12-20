using ScenarioSynthesis
using Test

@testset "predicates binary" begin
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)

    process!(ln)

    route1 = Route(LaneletID.([64, 143, 11]), ln);
    route2 = Route(LaneletID.([64, 143, 11, 97]), ln);

    actor1 = Actor(route1);
    actor2 = Actor(route2; a_min=-2.0);
    
    actors = ActorsDict([actor1, actor2]);

    ### define scenes
    rel1 = Vector{Relation}()
    rel2 = Vector{Relation}()
    
    scene1 = Scene(4.0, 8.0, rel1)
    scene2 = Scene(4.0, 8.0, rel2)
    
    scenes = ScenesDict([scene1, scene2]);

    ### build scenario
    scenario = Scenario(actors, scenes, ln);

    @test binary(Relation(IsBehind, 1, 2), scenario, StateCurv(10.0, 0, 0, 0, 0, 0), StateCurv(120.0, 0, 0, 0, 0, 0))
    @test !binary(Relation(IsBehind, 1, 2), scenario, StateCurv(120.0, 0, 0, 0, 0, 0), StateCurv(10.0, 0, 0, 0, 0, 0))
    @test binary(Relation(IsNextTo, 1,2), scenario, StateCurv(60.0, 0, 0, 0, 0, 0), StateCurv(65.0, 0, 0, 0, 0, 0))
    @test !binary(Relation(IsNextTo, 1,2), scenario, StateCurv(60.0, 0, 0, 0, 0, 0), StateCurv(100.0, 0, 0, 0, 0, 0))
    @test binary(Relation(IsInFront, 1,2), scenario, StateCurv(120.0, 0, 0, 0, 0, 0), StateCurv(10.0, 0, 0, 0, 0, 0))
    @test !binary(Relation(IsInFront, 1,2), scenario, StateCurv(10.0, 0, 0, 0, 0, 0), StateCurv(120.0, 0, 0, 0, 0, 0))
    @test binary(Relation(IsFaster, 1,2), scenario, StateCurv(10.0, 10.0, 0, 0, 0, 0), StateCurv(120.0, 5.0, 0, 0, 0, 0))
    @test !binary(Relation(IsFaster, 1,2), scenario, StateCurv(10.0, 5.0, 0, 0, 0, 0), StateCurv(120.0, 10.0, 0, 0, 0, 0))
    @test binary(Relation(IsSlower, 1,2), scenario, StateCurv(10.0, 5.0, 0, 0, 0, 0), StateCurv(120.0, 10.0, 0, 0, 0, 0))
    @test !binary(Relation(IsSlower, 1,2), scenario, StateCurv(10.0, 10.0, 0, 0, 0, 0), StateCurv(120.0, 5.0, 0, 0, 0, 0))
    @test binary(Relation(IsSameSpeed, 1,2), scenario, StateCurv(10.0, 10.0, 0, 0, 0, 0), StateCurv(120.0, 9.9, 0, 0, 0, 0))
    @test !binary(Relation(IsSameSpeed, 1,2), scenario, StateCurv(10.0, 10.0, 0, 0, 0, 0), StateCurv(120.0, 5.0, 0, 0, 0, 0))
    @test binary(Relation(IsStop, 1), scenario, StateCurv(10.0, 0.5, 0, 0, 0, 0))
    @test !binary(Relation(IsStop, 1), scenario, StateCurv(10.0, 1.5, 0, 0, 0, 0))
    @test binary(Relation(IsOnLanelet, 1, 64), scenario, StateCurv(20.0, 0, 0, 0, 0, 0))
    @test !binary(Relation(IsOnLanelet, 1, 64), scenario, StateCurv(120.0, 0, 0, 0, 0, 0))
    @test binary(Relation(IsOnSameLaneSection, 1, 2), scenario, StateCurv(120.0, 0, 0, 0, 0, 0), StateCurv(122.0, 0, 0, 0, 0, 0))
    @test !binary(Relation(IsOnSameLaneSection, 1, 2), scenario, StateCurv(120.0, 0, 0, 0, 0, 0), StateCurv(110.0, 0, 0, 0, 0, 0))
    @test binary(Relation(IsBeforeConflictSection, 1, 109), scenario, StateCurv(20.0, 0, 0, 0, 0, 0))
    @test !binary(Relation(IsBeforeConflictSection, 1, 109), scenario, StateCurv(120.0, 0, 0, 0, 0, 0))
    @test binary(Relation(IsOnConflictSection, 1, 109), scenario, StateCurv(120.0, 0, 0, 0, 0, 0))
    @test !binary(Relation(IsOnConflictSection, 1, 109), scenario, StateCurv(110.0, 0, 0, 0, 0, 0))
    @test binary(Relation(IsBehindConflictSection, 1, 109), scenario, StateCurv(140.0, 0, 0, 0, 0, 0))
    @test !binary(Relation(IsBehindConflictSection, 1, 109), scenario, StateCurv(20.0, 0, 0, 0, 0, 0))
end

@testset "predicates robustness" begin
    path = joinpath(@__DIR__, "..", "example_files", "DEU_Cologne-9_6_I-1.cr.xml")
    ln = ln_from_xml(path)

    process!(ln)

    route1 = Route(LaneletID.([64, 143, 11]), ln);
    route2 = Route(LaneletID.([64, 143, 11, 97]), ln);

    actor1 = Actor(route1);
    actor2 = Actor(route2; a_min=-2.0);
    
    actors = ActorsDict([actor1, actor2]);

    ### define scenes
    rel1 = Vector{Relation}()
    rel2 = Vector{Relation}()
    
    scene1 = Scene(4.0, 8.0, rel1)
    scene2 = Scene(4.0, 8.0, rel2)
    
    scenes = ScenesDict([scene1, scene2]);

    ### build scenario
    scenario = Scenario(actors, scenes, ln);

    @test robustness(Relation(IsBehind, 1, 2), scenario, StateCurv(10.0, 0, 0, 0, 0, 0), StateCurv(120.0, 0, 0, 0, 0, 0)) > 0 
    @test robustness(Relation(IsBehind, 1, 2), scenario, StateCurv(120.0, 0, 0, 0, 0, 0), StateCurv(10.0, 0, 0, 0, 0, 0)) < 0 
    @test robustness(Relation(IsNextTo, 1,2), scenario, StateCurv(60.0, 0, 0, 0, 0, 0), StateCurv(65.0, 0, 0, 0, 0, 0)) > 0 
    @test robustness(Relation(IsNextTo, 1,2), scenario, StateCurv(60.0, 0, 0, 0, 0, 0), StateCurv(100.0, 0, 0, 0, 0, 0)) < 0 
    @test robustness(Relation(IsInFront, 1,2), scenario, StateCurv(120.0, 0, 0, 0, 0, 0), StateCurv(10.0, 0, 0, 0, 0, 0)) > 0 
    @test robustness(Relation(IsInFront, 1,2), scenario, StateCurv(10.0, 0, 0, 0, 0, 0), StateCurv(120.0, 0, 0, 0, 0, 0)) < 0
    @test robustness(Relation(IsFaster, 1,2), scenario, StateCurv(10.0, 10.0, 0, 0, 0, 0), StateCurv(120.0, 5.0, 0, 0, 0, 0)) > 0 
    @test robustness(Relation(IsFaster, 1,2), scenario, StateCurv(10.0, 5.0, 0, 0, 0, 0), StateCurv(120.0, 10.0, 0, 0, 0, 0)) < 0 
    @test robustness(Relation(IsSlower, 1,2), scenario, StateCurv(10.0, 5.0, 0, 0, 0, 0), StateCurv(120.0, 10.0, 0, 0, 0, 0)) > 0 
    @test robustness(Relation(IsSlower, 1,2), scenario, StateCurv(10.0, 10.0, 0, 0, 0, 0), StateCurv(120.0, 5.0, 0, 0, 0, 0)) < 0 
    @test robustness(Relation(IsSameSpeed, 1,2), scenario, StateCurv(10.0, 10.0, 0, 0, 0, 0), StateCurv(120.0, 9.9, 0, 0, 0, 0)) > 0 
    @test robustness(Relation(IsSameSpeed, 1,2), scenario, StateCurv(10.0, 10.0, 0, 0, 0, 0), StateCurv(120.0, 5.0, 0, 0, 0, 0)) < 0
    @test robustness(Relation(IsStop, 1), scenario, StateCurv(10.0, 0.5, 0, 0, 0, 0)) > 0 
    @test robustness(Relation(IsStop, 1), scenario, StateCurv(10.0, 1.5, 0, 0, 0, 0)) < 0
    @test robustness(Relation(IsOnLanelet, 1, 64), scenario, StateCurv(20.0, 0, 0, 0, 0, 0)) > 0 
    @test robustness(Relation(IsOnLanelet, 1, 64), scenario, StateCurv(120.0, 0, 0, 0, 0, 0)) < 0 
    @test robustness(Relation(IsOnSameLaneSection, 1, 2), scenario, StateCurv(120.0, 0, 0, 0, 0, 0), StateCurv(122.0, 0, 0, 0, 0, 0)) > 0 
    @test robustness(Relation(IsOnSameLaneSection, 1, 2), scenario, StateCurv(120.0, 0, 0, 0, 0, 0), StateCurv(110.0, 0, 0, 0, 0, 0)) < 0 
    @test robustness(Relation(IsBeforeConflictSection, 1, 109), scenario, StateCurv(20.0, 0, 0, 0, 0, 0)) > 0
    @test robustness(Relation(IsBeforeConflictSection, 1, 109), scenario, StateCurv(120.0, 0, 0, 0, 0, 0)) < 0
    @test robustness(Relation(IsOnConflictSection, 1, 109), scenario, StateCurv(120.0, 0, 0, 0, 0, 0)) > 0 
    @test robustness(Relation(IsOnConflictSection, 1, 109), scenario, StateCurv(110.0, 0, 0, 0, 0, 0)) < 0 
    @test robustness(Relation(IsBehindConflictSection, 1, 109), scenario, StateCurv(140.0, 0, 0, 0, 0, 0)) > 0
    @test robustness(Relation(IsBehindConflictSection, 1, 109), scenario, StateCurv(20.0, 0, 0, 0, 0, 0)) < 0
end

@testset "constraints" begin
    @test true

    # TODO add tests so that every Relation is tested
end