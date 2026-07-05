import SwiftUI

struct ActionRowView: View {
    let event: MacroEvent
    let index: Int
    let nextTimestamp: TimeInterval?
    let isRunning: Bool

    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index + 1)")
                .font(.badge)
                .foregroundStyle(palette.textSecondary)
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6).fill(palette.buttonSubtle.opacity(0.6))
                )

            Image(systemName: event.type.sfSymbolName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(palette.buttonSubtle)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.displayName)
                    .font(.rowTitle)
                    .tracking(-0.13)
                    .foregroundStyle(palette.textPrimary)
                Text(detailString)
                    .font(.rowSubtitle)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                if isRunning {
                    Circle()
                        .fill(palette.textSecondary)
                        .frame(width: 5, height: 5)
                }
                Text(delayLabel)
                    .font(.duration)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: Metrics.rowRadius)
                .fill(isRunning ? palette.actionRowActive : palette.actionRowBg)
                .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.rowRadius)
                .stroke(
                    isRunning ? Color(hex: 0x7895B2, alpha: 0.60) : palette.borderSubtle,
                    lineWidth: 1
                )
        )
    }

    private var detailString: String {
        switch event.type {
        case .leftMouseDown, .leftMouseUp,
             .rightMouseDown, .rightMouseUp,
             .middleMouseDown, .middleMouseUp,
             .leftMouseDragged, .rightMouseDragged:
            if let p = event.position { return "at (\(Int(p.x)), \(Int(p.y)))" }
            return "—"
        case .scrollWheel:
            let dx = event.scrollDeltaX ?? 0
            let dy = event.scrollDeltaY ?? 0
            return String(format: "Δx %.0f, Δy %.0f", dx, dy)
        case .keyDown, .keyUp, .flagsChanged:
            if let chars = event.characters, !chars.isEmpty {
                return "\"\(chars)\""
            }
            return "keycode \(event.keyCode ?? 0)"
        }
    }

    private var delayLabel: String {
        guard let next = nextTimestamp else { return "—" }
        let delta = max(0, next - event.timestamp)
        return delta < 0.1
            ? String(format: "%.0fms", delta * 1000)
            : String(format: "%.1fs", delta)
    }
}
