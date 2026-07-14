using AcquaCalda
using StaticArrays
using Test

@testset "AcquaCalda.jl" begin
    @testset "construction" begin
        p = Particle(
            1,
            SA[0.0, 0.0, 0.0],
            SA[0.0, 0.0, 0.0],
            SA[0.0, 0.0, 0.0],
            SA[0.0, 0.0, 0.0],
            SA[0.0, 0.0, 0.0],
            0.01,
            1.0,
            0.0,
            300.0,
            800.0,
            2.0
        )
        @test p.id == 1
        @test p.radius == 0.01
    end

    @testset "wall" begin
        w = Wall(SA[0.0, 0.0, 1.0], SA[0.0, 0.0, 0.0])
        @test w.normal == SA[0.0, 0.0, 1.0]
    end

    @testset "run!" begin
        p = Particle(
            1,
            SA[0.0, 0.0, 1.0],
            SA[0.0, 0.0, 0.0],
            SA[0.0, 0.0, 0.0],
            SA[0.0, 0.0, 0.0],
            SA[0.0, 0.0, 0.0],
            0.01,
            1.0,
            0.4 * 1.0 * 0.01^2,
            300.0,
            800.0,
            2.0
        )
        w = Wall(SA[0.0, 0.0, 1.0], SA[0.0, 0.0, 0.0])
        sys = System(
            [p],
            [w],
            Contact[],
            LinearSpringDashpot(),
            FourierContact(),
            VelocityVerlet(),
            BruteForce(),
            9.81,
            1e-5,
            0.0
        )
        run!(sys, t_end = 0.001)
        @test sys.time >= 0.001
        @test p.position[3] < 1.0
    end
end
