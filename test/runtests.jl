using Test
using GeoInterface
using PlanarVisibility: Environment, PointSet, extract_points, angle_to_east

@testset "point sets" begin
    # empty set
    set = push!(PointSet(), [])
    @test length(set) == 0

    # add individual points
    set = push!(PointSet(), Point([0.0, 0.0]))
    @test length(set) == 1
    push!(set, Point([0.0, 0.0]))
    @test length(set) == 1
    push!(set, Point([0.0, 1.0]))
    @test length(set) == 2

    # add positions
    set = push!(PointSet(), [0.0, 0.0])
    @test length(set) == 1

    set = push!(PointSet(), [0.0, 0.0, 0.0])
    @test length(set) == 1

    # add line string coordinates
    set = push!(PointSet(), [[0.0, 0.0], [0.0, 1.0], [1.0, 0.0]])
    @test length(set) == 3

    # add polygon coordinates
    set = push!(PointSet(), [[[0.0, 0.0], [0.0, 1.0], [1.0, 0.0]]])
    @test length(set) == 3

    # add polygon with hole
    set = push!(PointSet(),
                Polygon([[[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [0.0, 0.0]],
                         [[0.1, 0.1], [0.1, 0.9], [0.9, 0.1], [0.1, 0.1]]]))
    @test length(set) == 6
end

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

@testset "compute angles" begin
    p1, p2, p3 = Point.([[0, 0], [1, 0], [1, 1]])
    @test angle_to_east(p1, p1) == 0.0
    @test angle_to_east(p1, p2) ≈ 0.0
    @test angle_to_east(p1, p3) ≈ 2π/8
    @test angle_to_east(p2, p1) ≈ 2π/2
    @test angle_to_east(p2, p3) ≈ 2π/4
    @test angle_to_east(p3, p1) ≈ 7/8 * 2π
    @test angle_to_east(p3, p2) ≈ 3/4 * 2π
end
