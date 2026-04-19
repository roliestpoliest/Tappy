import Foundation

struct PlaybackConfig {
    var speed: Double = 1.0
    var clickMultiplier: Int = 1
    var jitterAmount: Double = 0.0
    var useBezierCurves: Bool = false
    var bezierDeviation: Double = 30.0
    var bezierSteps: Int = 20
    var repeatCount: Int = 1
}
