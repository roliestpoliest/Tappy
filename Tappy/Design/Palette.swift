import SwiftUI

enum AppColorScheme: String, Codable {
    case light, dark, system

    var swiftUIScheme: ColorScheme? {
        switch self {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }
}

struct Palette {
    let scheme: ColorScheme

    var windowBg:        Color { scheme == .dark ? Color(hex: 0x1C1C1E) : Color(hex: 0xF5EFE6) }
    var sidebarBg:       Color { scheme == .dark ? Color(hex: 0x252527) : Color(hex: 0xF5EFE6) }
    var mainPaneBg:      Color { scheme == .dark ? Color(hex: 0x1C1C1E) : Color(hex: 0xEDE7DB) }
    var actionRowBg:     Color { scheme == .dark ? Color(hex: 0x2C2C2E) : Color(hex: 0xFFF8E9) }
    var actionRowActive: Color { Color(hex: 0x7895B2, alpha: scheme == .dark ? 0.12 : 0.25) }
    var playbackBarBg:   Color { scheme == .dark ? Color(hex: 0x161618) : Color(hex: 0xEDE7DB) }
    var floatingBg:      Color { scheme == .dark ? Color(hex: 0x1C1C1E, alpha: 0.9) : Color(hex: 0xF5EFE6) }
    var buttonSubtle:    Color { Color(hex: 0xAEBDCA, alpha: scheme == .dark ? 0.30 : 0.25) }
    var borderDefault:   Color { Color(hex: 0xAEBDCA, alpha: scheme == .dark ? 0.35 : 0.60) }
    var borderSubtle:    Color { Color(hex: 0xAEBDCA, alpha: scheme == .dark ? 0.16 : 0.40) }
    var textTitle:       Color { scheme == .dark ? Color(hex: 0xEAE0D5, alpha: 0.80) : Color(hex: 0x4A5A6A) }
    var textPrimary:     Color { scheme == .dark ? Color(hex: 0xEAE0D5) : Color(hex: 0x3D4F5E) }
    var textSecondary:   Color { Color(hex: 0x7895B2) }
    var accent:          Color { Color(hex: 0x7895B2) }
    var recordRed:       Color { Color(hex: 0xC0392B, alpha: 0.95) }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >>  8) & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: alpha
        )
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette(scheme: .light)
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
