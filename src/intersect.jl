# Intersection of line segments and utilities

@enum Orientation begin
    COUNTERCLOCKWISE = -1
    COLLINEAR        =  0
    CLOCKWISE        =  1
end

"Find orientation of three points in the plane."
function orientation(p::Point, q::Point, r::Point)
    pp, qq, rr = coordinates.([p, q, r])
    lhs = (qq[2] - pp[2])*(rr[1] - qq[1])
    rhs = (rr[2] - qq[2])*(qq[1] - pp[1])
    # check sign of (lhs - rhs)
    if isapprox(lhs, rhs) # zero
        return COLLINEAR
    elseif lhs < rhs      # negative
        return COUNTERCLOCKWISE
    else                  # positive
        return CLOCKWISE
    end
end

"Does q lie on segment [p,q] for collinear p, q and r?"
function collinear_intersect(p::Point, q::Point, r::Point)
    pp, qq, rr = coordinates.([p, q, r])
    x = min(pp[1], rr[1]) <= qq[1] <= max(pp[1], rr[1])
    y = min(pp[2], rr[2]) <= qq[2] <= max(pp[2], rr[2])
    return x && y
end

"Check whether segments [p1 q1] and [p2 q2] intersect."
function intersect_segments(p1::Point, q1::Point, p2::Point, q2::Point)
    # find all orientations of three points
    orient1 = orientation(p1, q1, p2)
    orient2 = orientation(p1, q1, q2)
    orient3 = orientation(p2, q2, p1)
    orient4 = orientation(p2, q2, q1)

    # general case (not parallel)
    if (orient1 != orient2) && (orient3 != orient4)
        return true
    end

    # special cases with collinear points
    if (((orient1 == COLLINEAR) && collinear_intersect(p1, p2, q1)) ||
        ((orient2 == COLLINEAR) && collinear_intersect(p1, q2, q1)) ||
        ((orient3 == COLLINEAR) && collinear_intersect(p2, p1, q2)) ||
        ((orient4 == COLLINEAR) && collinear_intersect(p2, q1, q2)))
        return true
    end

    # none of the above: not intersecting
    return false
end
