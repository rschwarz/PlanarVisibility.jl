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
            Polygon([[[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [0.0, 0.0]]])
        ])
        points, indices = extract_points(env)
        @test length(points) == 3
        @test length(indices) == 3
        @test points[1] == Point([0.0, 0.0])
        @test all(indices[points[i]] == i for i in 1:3)
    end

    @testset "polygon with hole" begin
        env = Environment([
            Polygon([[[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [0.0, 0.0]],
                     [[0.1, 0.1], [0.1, 0.9], [0.9, 0.1], [0.1, 0.1]]])
        ])
        points, indices = extract_points(env)
        @test length(points) == 6
        @test length(indices) == 6
        @test points[1] == Point([0.0, 0.0])
        @test all(indices[points[i]] == i for i in 1:6)
    end

    @testset "two touching polygons" begin
        env = Environment([
            Polygon([
                [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]],
                [[1.0, 0.0], [2.0, 0.0], [2.0, 1.0], [1.0, 1.0], [1.0, 0.0]]
            ])
        ])
        points, indices = extract_points(env)
        @test length(points) == 6
        @test length(indices) == 6
        @test points[1] == Point([0.0, 0.0])
        @test points[6] == Point([2.0, 1.0])
        @test all(indices[points[i]] == i for i in 1:6)
    end
end
