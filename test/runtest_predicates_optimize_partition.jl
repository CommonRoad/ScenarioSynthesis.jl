import Gurobi: Env

@testset "optimize partition" begin
    low = [1.0, 3.0, 2.0]
    upp = [2.0, 9.0, 5.0]
    env = Env()

    l, u = optimize_partition(low, upp, env)

    @test all(isapprox.(l, [1.0, 3.0, 4.0]))
    @test all(isapprox.(u, [2.0, 4.0, 5.0]))
end
