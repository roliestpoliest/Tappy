//
//  BezierMouseMover.swift
//  Tappy
//
//  Created by ujwal joshi on 4/17/26.
//

import Foundation
import Cocoa

class BezierMouseMover {
    func move(
        to end: CGPoint,
        duration: TimeInterval = 0.5,
        completion: (() -> Void)? = nil
    ) {
        let start = NSEvent.mouseLocation

        let cp1 = randomControlPoint(around: start)
        let cp2 = randomControlPoint(around: end)

        let steps = Int(duration * 60)

        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0...steps {
                let linearT = CGFloat(i) / CGFloat(steps)
                let t = self.smoothstep(linearT)

                let point = self.cubicBezier(
                    t: t,
                    p0: start,
                    p1: cp1,
                    p2: cp2,
                    p3: end
                )

                let jittered = self.addJitter(to: point)

                CGWarpMouseCursorPosition(jittered)
                usleep(useconds_t(1_000_000 / 60))
            }

            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    private func cubicBezier(
        t: CGFloat,
        p0: CGPoint,
        p1: CGPoint,
        p2: CGPoint,
        p3: CGPoint
    ) -> CGPoint {
        let oneMinusT = 1 - t

        let x = pow(oneMinusT, 3) * p0.x
            + 3 * pow(oneMinusT, 2) * t * p1.x
            + 3 * oneMinusT * pow(t, 2) * p2.x
            + pow(t, 3) * p3.x

        let y = pow(oneMinusT, 3) * p0.y
            + 3 * pow(oneMinusT, 2) * t * p1.y
            + 3 * oneMinusT * pow(t, 2) * p2.y
            + pow(t, 3) * p3.y

        return CGPoint(x: x, y: y)
    }

    private func smoothstep(_ t: CGFloat) -> CGFloat {
        return t * t * (3 - 2 * t)
    }
    
    private func randomControlPoint(around point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x + CGFloat.random(in: -100...100),
            y: point.y + CGFloat.random(in: -100...100)
        )
    }

    private func addJitter(to point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x + CGFloat.random(in: -0.5...0.5),
            y: point.y + CGFloat.random(in: -0.5...0.5)
        )
    }
}
