using Test
using GeoInterface
using PlanarVisibility: Environment, extract_points

@testset "extract_points" begin
    @testset "empty environment has no points" begin
        env = Environment([])
        set = extract_points(env)
        @test isempty(set.points)
        @test isempty(set.indices)
    end

    @testset "single polygon" begin
        env = Environment([
            Polygon([[[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [0.0, 0.0]]])
        ])
        set = extract_points(env)
        @test length(set.points) == 3
        @test length(set.indices) == 3
        @test set.points[1] == Point([0.0, 0.0])
        @test all(set.indices[set.points[i]] == i for i in 1:3)
    end

    @testset "polygon with hole" begin
        env = Environment([
            Polygon([[[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [0.0, 0.0]],
                     [[0.1, 0.1], [0.1, 0.9], [0.9, 0.1], [0.1, 0.1]]])
        ])
        set = extract_points(env)
        @test length(set.points) == 6
        @test length(set.indices) == 6
        @test set.points[1] == Point([0.0, 0.0])
        @test all(set.indices[set.points[i]] == i for i in 1:6)
    end

    @testset "two touching polygons" begin
        env = Environment([
            Polygon([
                [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]],
                [[1.0, 0.0], [2.0, 0.0], [2.0, 1.0], [1.0, 1.0], [1.0, 0.0]]
            ])
        ])
        set = extract_points(env)
        @test length(set.points) == 6
        @test length(set.indices) == 6
        @test set.points[1] == Point([0.0, 0.0])
        @test set.points[6] == Point([2.0, 1.0])
        @test all(set.indices[set.points[i]] == i for i in 1:6)
    end
end
