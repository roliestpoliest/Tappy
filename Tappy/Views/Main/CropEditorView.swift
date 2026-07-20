import SwiftUI

struct CropEditorView: View {
    let recording: MacroRecording

    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    @State private var showingConfirmation: Bool = false

    private enum Handle { case start, end }

    private var duration: TimeInterval { max(recording.duration, 0.001) }

    private var startTime: TimeInterval {
        appState.cropRange?.lowerBound ?? 0
    }

    private var endTime: TimeInterval {
        appState.cropRange?.upperBound ?? duration
    }

    private var keptEventCount: Int {
        recording.events.filter { $0.timestamp >= startTime && $0.timestamp <= endTime }.count
    }

    private var canSave: Bool { keptEventCount > 0 && endTime > startTime }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow
            timelineBar
            axisLabels
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .background(palette.playbackBarBg)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.borderDefault).frame(height: 1)
        }
        .alert("Replace recording?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Save Crop", role: .destructive) {
                try? appState.applyCrop(startTime: startTime, endTime: endTime)
            }
        } message: {
            Text("This will overwrite \u{201C}\(recording.name)\u{201D} with the range \(format(startTime))\u{2013}\(format(endTime)) and drop \(recording.events.count - keptEventCount) action\(recording.events.count - keptEventCount == 1 ? "" : "s"). This cannot be undone.")
        }
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Crop Recording")
                    .font(.rowTitle)
                    .foregroundStyle(palette.textPrimary)
                Text("\(format(startTime)) \u{2013} \(format(endTime)) \u{00B7} keeps \(keptEventCount) of \(recording.events.count) actions")
                    .font(.rowSubtitle)
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
            pillButton("Cancel", tint: palette.buttonSubtle, textColor: palette.textPrimary) {
                appState.cancelCropping()
            }
            pillButton("Save Crop", tint: palette.accent, textColor: .white) {
                showingConfirmation = true
            }
            .disabled(!canSave)
            .opacity(canSave ? 1.0 : 0.4)
        }
    }

    private func pillButton(
        _ title: String,
        tint: Color,
        textColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(textColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(tint))
        }
        .buttonStyle(.plain)
    }

    private var timelineBar: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let startX = w * CGFloat(startTime / duration)
            let endX = w * CGFloat(endTime / duration)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(palette.borderSubtle)
                    .frame(height: 6)

                Capsule()
                    .fill(palette.accent.opacity(0.85))
                    .frame(width: max(0, endX - startX), height: 6)
                    .offset(x: startX)

                handle
                    .offset(x: startX - handleSize / 2)
                    .gesture(dragGesture(for: .start, width: w))

                handle
                    .offset(x: endX - handleSize / 2)
                    .gesture(dragGesture(for: .end, width: w))
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 22)
    }

    private var handleSize: CGFloat { 14 }

    private var handle: some View {
        Circle()
            .fill(palette.accent)
            .frame(width: handleSize, height: handleSize)
            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
            .shadow(color: palette.accent.opacity(0.5), radius: 3, y: 1)
            .contentShape(Circle().inset(by: -6))
    }

    private var axisLabels: some View {
        HStack {
            Text(format(0))
                .font(.duration)
                .foregroundStyle(palette.textSecondary)
            Spacer()
            Text(format(recording.duration))
                .font(.duration)
                .foregroundStyle(palette.textSecondary)
        }
    }

    private func dragGesture(for handle: Handle, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard width > 0 else { return }
                let ratio = max(0, min(1, value.location.x / width))
                let t = TimeInterval(ratio) * duration
                let minGap: TimeInterval = 0.05
                switch handle {
                case .start:
                    let clamped = min(t, endTime - minGap)
                    appState.cropRange = max(0, clamped)...endTime
                case .end:
                    let clamped = max(t, startTime + minGap)
                    appState.cropRange = startTime...min(duration, clamped)
                }
            }
    }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        let cs = Int((t - floor(t)) * 10)
        return String(format: "%d:%02d.%d", m, s, cs)
    }
}
