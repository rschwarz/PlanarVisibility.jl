using Test
using GeoInterface
using PlanarVisibility: Environment, extract_points

@testset "extract_points" begin
    @testset "empty environment has no points" begin
        env = Environment([])
        points, indices = extract_points(env)
        @test isempty(points)
        @test isempty(indices)
    end

    @testset "single polygon" begin
        env = Environment([
            Polygon([[[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]]])
        ])
        points, indices = extract_points(env)
        @test length(points) == 3
        @test length(indices) == 3
        @test points[1] == Point([0.0, 0.0])
        @test indices[points[1]] == 1
        @test indices[points[2]] == 2
        @test indices[points[3]] == 3
    end
end
