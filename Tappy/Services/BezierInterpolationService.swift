import CoreGraphics

enum BezierInterpolationService {

    /// Returns interpolated CGPoints along a cubic Bézier from `start` to `end`.
    /// Control points are pseudo-randomly offset perpendicular to the path
    /// to produce natural, human-like curves.
    static func interpolate(
        from start: CGPoint,
        to end: CGPoint,
        steps: Int? = nil
    ) -> [CGPoint] {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = hypot(dx, dy)

        guard distance > 0 else { return [end] }

        let stepCount = steps ?? max(10, Int(distance / 12))

        // Perpendicular unit vector to the start→end line
        let perpX = -dy / distance
        let perpY =  dx / distance

        // Control points offset perpendicularly in opposite directions — produces an S-curve
        let jitter1 = Double.random(in: 0.10...0.25) * distance
        let jitter2 = Double.random(in: 0.10...0.25) * distance

        let p1 = CGPoint(x: start.x + dx * 0.33 + perpX * jitter1,
                         y: start.y + dy * 0.33 + perpY * jitter1)
        let p2 = CGPoint(x: start.x + dx * 0.67 - perpX * jitter2,
                         y: start.y + dy * 0.67 - perpY * jitter2)

        return (0..<stepCount).map { step in
            let t = Double(step) / Double(stepCount - 1)
            return cubicBezier(t: t, p0: start, p1: p1, p2: p2, p3: end)
        }
    }

    // MARK: - Private

    private static func cubicBezier(
        t: Double,
        p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint
    ) -> CGPoint {
        let u = 1.0 - t
        let x = u*u*u * p0.x
             + 3*u*u*t * p1.x
             + 3*u*t*t * p2.x
             +   t*t*t * p3.x
        let y = u*u*u * p0.y
             + 3*u*u*t * p1.y
             + 3*u*t*t * p2.y
             +   t*t*t * p3.y
        return CGPoint(x: x, y: y)
    }
}
