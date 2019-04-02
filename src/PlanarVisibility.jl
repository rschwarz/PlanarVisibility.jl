module PlanarVisibility

using GeoInterface: Point, Polygon, coordinates, xcoord, ycoord
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

"Visibility graph."
struct VisibilityGraph
    env::Environment               # initial environment
    points::Array{Point}           # all points (including environment)
    indices::Dict{Point, Int64}    # map from point to array index
    graph::SimpleGraph{Int64}      # edges of visibility relation
end

VisibilityGraph(env::Environment) = construct_graph(env)


#
# Utilities
#

"Extract unique points from given environment."
function extract_points(env::Environment)
    points = Point[]
    indices = Dict{Point, Int64}()

    for polygon in env.polygons
        for linestring in coordinates(polygon)
            for position in coordinates(linestring)
                point = Point(position)
                if !haskey(indices, point)
                    push!(points, point)
                    indices[point] = length(points)
                end
            end
        end
    end

    return points, indices
end


#
# Constructing visibility graphs
#

function construct_graph(env::Environment)
    # extract points from environment
    points, indices = extract_points(env)

    # build graph from disconnected points
    n = length(points)
    graph = SimpleGraph(n)

    # assemble result
    return VisibilityGraph(env, points, indices, graph)
end


#
# Extending visibility graphs
#


end
