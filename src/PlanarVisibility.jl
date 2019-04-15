module PlanarVisibility

import Base: length, push!, getindex
using LinearAlgebra

using GeoInterface
using LightGraphs

include("points.jl")
include("intersect.jl")


#
# Types
#

"Environment of obstacles."
struct Environment
    # TODO: make types parametric?
    # TODO: support linestrings?
    polygons::Array{Polygon}
end

"Visibility graph."
struct VisibilityGraph
    env::Environment               # initial environment
    pointset::PointSet             # all points (including environment)
    graph::SimpleGraph{Int64}      # edges of visibility relation
end

VisibilityGraph(env::Environment) = construct_graph(env)


#
# Utilities
#

"Extract unique points from given environment."
function extract_points(env::Environment)
    points = PointSet()
    for polygon in env.polygons
        push!(points, polygon)
    end
    return points
end

"Extract edges from given environment."
function extract_edges(env::Environment, points::PointSet)
    # start with disconnected graph
    n = length(points)
    graph = SimpleGraph(n)

    # iterate over all polygons
    for polygon in env.polygons
        # iterate over outer and inner line strings (coordinates)
        for str in coordinates(polygon)
            # iterate over pairs of positions, with wrap-around
            for (pos1, pos2) in zip(str, [str[2:end]; str[1:1]])
                pos1 == pos2 && continue # skip with explicit close
                add_edge!(graph, points[pos1], points[pos2])
            end
        end
    end

    return graph
end

"Angle from origin to point rel. to horiz. line going east."
function angle_to_east(origin::Point, point::Point)::Float64
    dx, dy = coordinates(point) - coordinates(origin)
    angle = asin(abs(dy) / norm([dx, dy]))
    if dy > 0.0 # top
        if dx >= 0.0 # right
            return angle
        else # dx < 0, left
            return π - angle
        end
    elseif dy < 0.0
        if dx >= 0.0 # right
            return 2π - angle
        else # dx < 0, left
            return π + angle
        end
    else # dy == 0.0
        if dx >= 0.0
            return 0.0
        else # dx < 0.0
            return π
        end
    end
end

"Find permutation to iterate thru points in counterclockwise order."
function sortperm_ccw(points::Vector{Point}, origin::Point)::Vector{Int}
    by = p -> angle_to_east(origin, p)
    return sortperm(points, by=by)
end

"Sorted edge for unique representation"
function sorted(edge::Edge)
    if edge.src < edge.dst
        return edge
    else
        return reverse(edge)
    end
end

#
# Constructing visibility graphs
#

"Find all visible points from given origin."
function visible_points(points::PointSet, envgraph::SimpleGraph, origin::Int64)
    # point at origin
    orig = points[origin]

    # starting with east-looking horizontal ray
    xmax = maximum([xcoord(coordinates(p)) for p in points.points])
    ray = Point([xmax + 1.0, ycoord(coordinates(orig))])

    # currently intersecting edges
    open_edges = Set{Edge}()
    for e in edges(envgraph)
        # skip non-intersecting edges
        intersect_segments(orig, ray, points[e.src], points[e.dst]) || continue
        # skip those edges where the endpoint is on the ray
        !collinear_intersect(orig, points[e.src], ray) || continue
        !collinear_intersect(orig, points[e.dst], ray) || continue
        push!(open_edges, sorted(e))
    end

    # counterclockwise sweep to consider all candidates
    perm = sortperm_ccw(points.points, orig)
    result = Int[]
    for index in perm
        index == origin && continue
        cand = points[index]

        # open edges: rm incident, clockwise edges
        for neighbor in neighbors(envgraph, index)
            edge = sorted(Edge(index, neighbor))
            edge in open_edges || continue
            if orientation(orig, cand, points[neighbor]) == CLOCKWISE
                delete!(open_edges, edge)
            end
        end

        visible = true
        for e in open_edges
            if intersect_segments(orig, cand, points[e.src], points[e.dst])
                visible = false
                break
            end
        end

        # TODO: check if line-of-sight is inside of polygon

        if visible
            push!(result, index)
        end

        # open edges: add incident, counterclockwise edges
        for neighbor in neighbors(envgraph, index)
            if orientation(orig, cand, points[neighbor]) == COUNTERCLOCKWISE
                push!(open_edges, sorted(Edge(index, neighbor)))
            end
        end
    end

    return result
end

function construct_graph(env::Environment)
    # extract points from environment
    points = extract_points(env)

    # extract edges from environment
    envgraph = extract_edges(env, points)

    # build graph from disconnected points
    n = length(points)
    graph = SimpleGraph(n)

    # iterate over all points and find out what can be seen from there
    for i in 1:n
        for j in visible_points(points, envgraph, i)
            add_edge!(graph, i, j)
        end
    end

    # assemble result
    return VisibilityGraph(env, points, graph)
end


#
# Extending visibility graphs
#


end
