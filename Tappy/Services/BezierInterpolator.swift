import CoreGraphics
import Foundation

struct BezierInterpolator {
    nonisolated static func points(
        from start: CGPoint,
        to end: CGPoint,
        deviation: Double,
        steps: Int
    ) -> [CGPoint] {
        guard steps > 1 else { return [start, end] }

        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 0 else { return Array(repeating: start, count: steps) }

        let perpX = -dy / length
        let perpY = dx / length

        let p1 = CGPoint(
            x: start.x + dx * 0.33 + perpX * deviation,
            y: start.y + dy * 0.33 + perpY * deviation)
        let p2 = CGPoint(
            x: start.x + dx * 0.67 - perpX * deviation,
            y: start.y + dy * 0.67 - perpY * deviation)

        return (0..<steps).map { i in
            let t = Double(i) / Double(steps - 1)
            let u = 1.0 - t
            return CGPoint(
                x: u*u*u*start.x + 3*u*u*t*p1.x + 3*u*t*t*p2.x + t*t*t*end.x,
                y: u*u*u*start.y + 3*u*u*t*p1.y + 3*u*t*t*p2.y + t*t*t*end.y)
        }
    }
}
