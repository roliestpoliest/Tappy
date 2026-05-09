import Foundation

struct PlaybackConfig: Codable, Equatable {
    var speed: Double
    var repeatCount: Int
    var isLooping: Bool     // takes precedence over repeatCount when true

    static let `default` = PlaybackConfig(speed: 1.0, repeatCount: 1, isLooping: false)
    static let validSpeeds: [Double] = [0.25, 0.5, 1.0, 1.5, 2.0, 4.0]
}
