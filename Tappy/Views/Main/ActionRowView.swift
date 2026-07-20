import SwiftUI

struct ActionRowView: View {
    let step: ActionStep
    let index: Int
    let nextStepStart: TimeInterval?
    let isRunning: Bool
    let isDeleteEnabled: Bool
    let onDelete: () -> Void

    @Environment(\.palette) private var palette
    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index + 1)")
                .font(.badge)
                .foregroundStyle(palette.textSecondary)
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6).fill(palette.buttonSubtle.opacity(0.6))
                )

            Image(systemName: step.iconName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(palette.buttonSubtle)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(step.displayName)
                    .font(.rowTitle)
                    .tracking(-0.13)
                    .foregroundStyle(palette.textPrimary)
                Text(step.detailString)
                    .font(.rowSubtitle)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(step.detailString)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                if isRunning {
                    Circle()
                        .fill(palette.textSecondary)
                        .frame(width: 5, height: 5)
                }
                Text(delayLabel)
                    .font(.duration)
                    .foregroundStyle(palette.textSecondary)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(palette.recordRed)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isDeleteEnabled)
                .opacity(isHovered ? (isDeleteEnabled ? 1 : 0.4) : 0)
                .help("Delete this action")
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
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }

    private var delayLabel: String {
        guard let next = nextStepStart else { return "—" }
        let delta = max(0, next - step.endTimestamp)
        return delta < 0.1
            ? String(format: "%.0fms", delta * 1000)
            : String(format: "%.1fs", delta)
    }
}
