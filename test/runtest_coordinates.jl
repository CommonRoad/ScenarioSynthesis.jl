using ScenarioSynthesis
using Test

import Random.MersenneTwister

@testset "transformation" begin
    rng = MersenneTwister(1234);

    pos_vec = [
        Pos(FCart, 0, 0),
        Pos(FCart, 0, 2),
        Pos(FCart, 1, 4),
        Pos(FCart, 3, 6),
        Pos(FCart, 6, 8)
    ]
    
    frame = TransFrame(FLanelet, pos_vec)

    for i in 1:10000
        pos_rnd = Pos(FLanelet, rand()*frame.cum_dst[end], (rand()-0.5)*8) # FLanelet
        pos_cart0 = transform(pos_rnd, frame) # FCart
        pos_curv1 = transform(FLanelet, pos_cart0, frame) # FLanelet
        pos_cart1 = transform(pos_curv1, frame) # FCart
        pos_curv2 = transform(FLanelet, pos_cart1, frame) # FLanelet
        
        @test isapprox(pos_cart0, pos_cart1)
        @test isapprox(pos_curv1, pos_curv2)
    end
end