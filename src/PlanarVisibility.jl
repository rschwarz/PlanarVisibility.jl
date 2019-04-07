module PlanarVisibility

import Base: length, push!, getindex
using LinearAlgebra

using GeoInterface
using LightGraphs: SimpleGraph, add_edge!

include("points.jl")


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
    diff = coordinates(point) - coordinates(origin)
    distance = norm(diff)
    altitude = diff[2]
    if altitude > 0.0
        return asin(altitude / distance)
    elseif altitude == 0.0
        if diff[1] >= 0.0
            return 0.0
        else
            return π
        end
    else # altitude < 0.0
        return 2π + asin(altitude / distance)
    end
end

"Find permutation to iterate thru points in counterclockwise order."
function sortperm_ccw(points::Vector{Point}, origin::Point)::Vector{Int}
    by = p -> angle_to_east(origin, p)
    return sortperm(points, by=by)
end


#
# Constructing visibility graphs
#

function construct_graph(env::Environment)
    # extract points from environment
    points = extract_points(env)

    # extract edges from environment
    envgraph = extract_edges(env, points)

    # build graph from disconnected points
    n = length(points)
    graph = SimpleGraph(n)

    # assemble result
    return VisibilityGraph(env, points, graph)
end


#
# Extending visibility graphs
#


end
