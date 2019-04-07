# Types and functions related to (sets of) points

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
