using ScenarioSynthesis
using Test

@testset "LineSection intersection" begin
    p0 = Pos(FCart, 0, 0)
    p1 = Pos(FCart, 1, 0)
    p2 = Pos(FCart, 2, 0)
    p3 = Pos(FCart, 3, 0)
    p4 = Pos(FCart, 4, 0)
    p5 = Pos(FCart, 5, 0)

    p6 = Pos(FCart, 1, -1)
    p7 = Pos(FCart, 1, 0)
    p8 = Pos(FCart, 1, 1)
    p9 = Pos(FCart, 1, 2)
    p10 = Pos(FCart, 1, 3)

    ls0 = LineSection(p0, p2)
    ls1 = LineSection(p1, p3)
    @test is_intersect(ls0, ls1) == false # TODO how should this be defined? 

    ls2 = LineSection(p2, p4)
    @test is_intersect(ls0, ls2) == false # TODO how should this be defined? 

    ls3 = LineSection(p3, p5)
    @test is_intersect(ls0, ls3) == false

    ls4 = LineSection(p6, p8)
    @test is_intersect(ls0, ls4) == true

    ls5 = LineSection(p7, p9)
    @test is_intersect(ls0, ls5) == false # TODO how should this be defined?

    ls6 = LineSection(p8, p10)
    @test is_intersect(ls0, ls6) == false
end

@testset "Polygon intersection" begin # TODO is_in is_out cases not considered yet
    poly0 = Polygon(FCart, [0 0 -1 -1; 0 -1 -1 0])
    poly1 = Polygon(FCart, [0 0 1 1; 0 -1 -1 0])
    @test is_intersect(poly0, poly1) == false

    poly2 = Polygon(FCart, [-.5 -.5 .5 .5; .5 -.5 -.5 .5])
    @test is_intersect(poly0, poly2) == true
end