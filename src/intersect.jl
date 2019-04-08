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
