module PlanarVisibility

import Base: length, push!
using GeoInterface
using LightGraphs: SimpleGraph

#
# Types
#

"Environment of obstacles."
struct Environment
    # TODO: make types parametric?
    # TODO: support linestrings?
    polygons::Array{Polygon}
end

"Set of points with indices."
struct PointSet
    points::Array{Point}          # coordinates, insertion order
    indices::Dict{Point, Int64}   # find index from point
end
PointSet() = PointSet([], Dict())

length(set::PointSet) = length(set.points)

"Add single point to set."
function push!(set::PointSet, point::Point)
    if !haskey(set.indices, point)
        push!(set.points, point)
        set.indices[point] = length(set.points)
    end
    return set
end

"Add single point (from position) to set."
push!(set::PointSet, pos::Position) = push!(set, Point(pos))

"Add all points of a geometry to set recursively."
function push!(set::PointSet, coords::Vector{T}) where T
    for c in coords
        push!(set, c)
    end
    return set
end

"Add all points of a geometry to set recursively."
push!(set::PointSet, geo::AbstractGeometry) = push!(set, coordinates(geo))

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
