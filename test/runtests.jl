using Test
using GeoInterface
using LightGraphs
using PlanarVisibility
const PV = PlanarVisibility

@testset "point sets" begin
    # empty set
    set = push!(PV.PointSet(), [])
    @test length(set) == 0

    # add individual points
    set = push!(PV.PointSet(), Point([0.0, 0.0]))
    @test length(set) == 1
    push!(set, Point([0.0, 0.0]))
    @test length(set) == 1
    push!(set, Point([0.0, 1.0]))
    @test length(set) == 2

    # add positions
    set = push!(PV.PointSet(), [0.0, 0.0])
    @test length(set) == 1

    set = push!(PV.PointSet(), [0.0, 0.0, 0.0])
    @test length(set) == 1

    # add line string coordinates
    set = push!(PV.PointSet(), [[0.0, 0.0], [0.0, 1.0], [1.0, 0.0]])
    @test length(set) == 3

    # add polygon coordinates
    set = push!(PV.PointSet(), [[[0.0, 0.0], [0.0, 1.0], [1.0, 0.0]]])
    @test length(set) == 3

    # add polygon with hole
    set = push!(PV.PointSet(),
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
        env = PV.Environment([])
        set = PV.extract_points(env)
        @test isempty(set.points)
        @test isempty(set.indices)
    end

    @testset "single polygon" begin
        env = PV.Environment([
            Polygon([[[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [0.0, 0.0]]])
        ])
        set = PV.extract_points(env)
        @test length(set.points) == 3
        @test length(set.indices) == 3
        @test set.points[1] == Point([0.0, 0.0])
        @test all(set.indices[set.points[i]] == i for i in 1:3)
    end

    @testset "polygon with hole" begin
        env = PV.Environment([
            Polygon([[[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [0.0, 0.0]],
                     [[0.1, 0.1], [0.1, 0.9], [0.9, 0.1], [0.1, 0.1]]])
        ])
        set = PV.extract_points(env)
        @test length(set.points) == 6
        @test length(set.indices) == 6
        @test set.points[1] == Point([0.0, 0.0])
        @test all(set.indices[set.points[i]] == i for i in 1:6)
    end

    @testset "two touching polygons" begin
        env = PV.Environment([
            Polygon([
                [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0], [0.0, 0.0]],
                [[1.0, 0.0], [2.0, 0.0], [2.0, 1.0], [1.0, 1.0], [1.0, 0.0]]
            ])
        ])
        set = PV.extract_points(env)
        @test length(set.points) == 6
        @test length(set.indices) == 6
        @test set.points[1] == Point([0.0, 0.0])
        @test set.points[6] == Point([2.0, 1.0])
        @test all(set.indices[set.points[i]] == i for i in 1:6)
    end
end

@testset "extract_edges" begin
    # empty environment
    env = PV.Environment([])
    set = PV.extract_points(env)
    graph = PV.extract_edges(env, set)
    @test nv(graph) == 0
    @test ne(graph) == 0

    # polygon with hole
    env = PV.Environment([
        Polygon([[[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [0.0, 0.0]],
                 [[0.1, 0.1], [0.1, 0.9], [0.9, 0.1], [0.1, 0.1]]])])
    set = PV.extract_points(env)
    graph = PV.extract_edges(env, set)
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
    # 4  3
    # 1  2
    p1, p2, p3, p4 = Point.([[0, 0], [1, 0], [1, 1], [0, 1]])
    @test PV.angle_to_east(p1, p1) == 0.0
    @test PV.angle_to_east(p1, p2) ≈ 0.0
    @test PV.angle_to_east(p1, p3) ≈ 2π/8
    @test PV.angle_to_east(p1, p4) ≈ 2π/4
    @test PV.angle_to_east(p2, p1) ≈ 2π/2
    @test PV.angle_to_east(p2, p3) ≈ 2π/4
    @test PV.angle_to_east(p2, p4) ≈ 3/8 * 2π
    @test PV.angle_to_east(p3, p1) ≈ 5/8 * 2π
    @test PV.angle_to_east(p3, p2) ≈ 3/4 * 2π
    @test PV.angle_to_east(p3, p4) ≈ 2π/2
    @test PV.angle_to_east(p4, p1) ≈ 3/4 * 2π
    @test PV.angle_to_east(p4, p2) ≈ 7/8 * 2π
    @test PV.angle_to_east(p4, p3) ≈ 0.0
end

@testset "sorting points in counter clockwise order" begin
    #  4  3
    #  1  2
    p1, p2, p3, p4 = Point.([[0, 0], [1, 0], [1, 1], [0, 1]])

    @test PV.sortperm_ccw([p2, p3, p4], p1) == [1, 2, 3]
    @test PV.sortperm_ccw([p4, p2, p3], p1) == [2, 3, 1]
    @test PV.sortperm_ccw([p3, p2, p1], p4) == [1, 3, 2]
    @test PV.sortperm_ccw([p1, p2, p3, p4], p1) == [1, 2, 3, 4]

    #  1 2
    # 3   4
    #  5 6
    q1, q2, q3, q4, q5, q6 = Point.(
        [[1., 2.], [2., 2.], [0., 1.], [3., 1.], [1., 0.], [2., 0.]])

    @test PV.sortperm_ccw([q1, q2, q3, q4, q5, q6], q1) == [1, 2, 3, 5, 6, 4]
    @test PV.sortperm_ccw([q1, q2, q3, q4, q5, q6], q3) == [3, 4, 2, 1, 5, 6]
    @test PV.sortperm_ccw([q1, q2, q3, q4, q5, q6], q5) == [5, 6, 4, 2, 1, 3]
end

@testset "sorted edges" begin
    @test PV.sorted(Edge(1, 2)) == Edge(1, 2)
    @test PV.sorted(Edge(1, 1)) == Edge(1, 1)
    @test PV.sorted(Edge(2, 1)) == Edge(1, 2)
end

@testset "triangle orientation" begin
    # p -- q -- r
    p, q, r = Point.([[0.0, 0.0], [1.0, 2.0], [2.0, 4.0]])
    @test PV.orientation(p, q, r) == PV.COLLINEAR
    @test PV.orientation(r, q, p) == PV.COLLINEAR
    @test PV.orientation(q, r, p) == PV.COLLINEAR
    @test PV.orientation(r, p, q) == PV.COLLINEAR
    @test PV.orientation(q, p, r) == PV.COLLINEAR
    @test PV.orientation(p, r, q) == PV.COLLINEAR

    #   ,q.
    # p'---`r
    p, q, r = Point.([[0.0, 0.0], [1.0, 1.0], [2.0, 0.0]])
    @test PV.orientation(p, q, r) == PV.CLOCKWISE
    @test PV.orientation(r, q, p) == PV.COUNTERCLOCKWISE
    @test PV.orientation(q, r, p) == PV.CLOCKWISE
    @test PV.orientation(r, p, q) == PV.CLOCKWISE
    @test PV.orientation(q, p, r) == PV.COUNTERCLOCKWISE
    @test PV.orientation(p, r, q) == PV.COUNTERCLOCKWISE
end

@testset "collinear intersection" begin
    # p -- q -- r
    p, q, r = Point.([[0.0, 0.0], [1.0, 2.0], [2.0, 4.0]])
    @test PV.collinear_intersect(p, q, r) == true
    @test PV.collinear_intersect(r, q, p) == true
    @test PV.collinear_intersect(q, r, p) == false
    @test PV.collinear_intersect(r, p, q) == false
    @test PV.collinear_intersect(q, p, r) == false
    @test PV.collinear_intersect(p, r, q) == false
end

@testset "intersecting segments" begin
    # \/
    # /\
    points = Point.([[0., 0.], [1., 1.], [1., 0.], [0., 1.]])
    @test PV.intersect_segments(points...) == true
    # | |
    # | |
    points = Point.([[0., 0.], [0., 1.], [1., 0.], [1., 1.]])
    @test PV.intersect_segments(points...) == false
    # |
    # |__
    points = Point.([[0., 0.], [0., 1.], [0., 0.], [1., 0.]])
    @test PV.intersect_segments(points...) == true
    # |
    # | __
    points = Point.([[0., 0.], [0., 1.], [1., 0.], [2., 0.]])
    @test PV.intersect_segments(points...) == false
    # -- --
    points = Point.([[0., 0.], [0., 2.], [0., 3.], [0., 5.]])
    @test PV.intersect_segments(points...) == false
    # -=-  (parallel but intersecting)
    points = Point.([[0., 0.], [0., 2.], [0., 1.], [0., 5.]])
    @test PV.intersect_segments(points...) == true
end

@testset "visible points -- lines" begin
    #  1-2
    # 3---4
    #  5-6
    points = PV.PointSet()
    push!(points, [[1.0, 2.0], [2.0, 2.0],
                   [0.0, 1.0], [3.0, 1.0],
                   [1.0, 0.0], [2.0, 0.0]])
    @test length(points) == 6

    graph = SimpleGraph(6)
    add_edge!(graph, 1, 2)
    add_edge!(graph, 3, 4)
    add_edge!(graph, 5, 6)

    @test PV.visible_points(points, graph, 1) == [2, 3, 4]
end
