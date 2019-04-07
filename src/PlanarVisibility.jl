module PlanarVisibility

import Base: length, push!
using LinearAlgebra

using GeoInterface
using LightGraphs: SimpleGraph

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
