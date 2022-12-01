using ScenarioSynthesis
using Test

import ScenarioSynthesis.pos_matrix2vector
import Random.MersenneTwister

@testset "transformation" begin
    rng = MersenneTwister(1234);

    pos_vec = pos_matrix2vector(
        FCart,
        Matrix{Float64}([
            0 0
            0 2
            1 4
            3 6
            6 8
        ])
    )
    frame = TransFrame(pos_vec)

    for i in 1:10000
        pos_rnd = Pos(FCurv, rand()*frame.cum_dst[end], (rand()-0.5)*8)
        pos_cart0 = transform(pos_rnd, frame)
        pos_curv1 = transform(pos_cart0, frame)
        pos_cart1 = transform(pos_curv1, frame)
        pos_curv2 = transform(pos_cart1, frame)
        
        @test isapprox(pos_cart0, pos_cart1)
        @test isapprox(pos_curv1, pos_curv2)
    end
end