using Test
using GeoInterface
using PlanarVisibility: Environment, PointSet, extract_points, extract_edges,
    angle_to_east, sortperm_ccw, intersect_segments
using LightGraphs: nv, ne, edges, neighbors

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

    # test getindex
    @test set[1] == Point([0.0, 0.0])
    @test set[Point([0.0, 0.0])] == 1
    @test set[[0.0, 0.0]] == 1
    @test set[4] == Point([0.1, 0.1])
    @test set[Point([0.1, 0.1])] == 4
    @test set[[0.1, 0.1]] == 4
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

@testset "extract_edges" begin
    # empty environment
    env = Environment([])
    set = extract_points(env)
    graph = extract_edges(env, set)
    @test nv(graph) == 0
    @test ne(graph) == 0

    # polygon with hole
    env = Environment([
        Polygon([[[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [0.0, 0.0]],
                 [[0.1, 0.1], [0.1, 0.9], [0.9, 0.1], [0.1, 0.1]]])])
    set = extract_points(env)
    graph = extract_edges(env, set)
    @test nv(graph) == 6
    @test ne(graph) == 6
    @test neighbors(graph, 1) == [2, 3]
    @test neighbors(graph, 2) == [1, 3]
    @test neighbors(graph, 3) == [1, 2]
    @test neighbors(graph, 4) == [5, 6]
    @test neighbors(graph, 5) == [4, 6]
    @test neighbors(graph, 6) == [4, 5]
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

@testset "sorting points in counter clockwise order" begin
    #  4  3
    #  1  2
    p1, p2, p3, p4 = Point.([[0, 0], [1, 0], [1, 1], [0, 1]])

    @test sortperm_ccw([p2, p3, p4], p1) == [1, 2, 3]
    @test sortperm_ccw([p4, p2, p3], p1) == [2, 3, 1]
    @test sortperm_ccw([p3, p2, p1], p4) == [1, 3, 2]
end

@testset "intersecting segments" begin
    # \/
    # /\
    @test intersect_segments([0., 0.], [1., 1.], [1., 0.], [0., 1.]) == true
    # | |
    # | |
    @test intersect_segments([0., 0.], [0., 1.], [1., 0.], [1., 1.]) == false
    # |
    # |__
    @test intersect_segments([0., 0.], [0., 1.], [0., 0.], [1., 0.]) == true
    # |
    # | __
    @test intersect_segments([0., 0.], [0., 1.], [1., 0.], [2., 0.]) == false
    # -- --
    @test intersect_segments([0., 0.], [0., 2.], [0., 3.], [0., 5.]) == false
    # -=-  (parallel but intersecting)
    @test_broken intersect_segments([0., 0.], [0., 2.], [0., 1.], [0., 5.]) == true
end
