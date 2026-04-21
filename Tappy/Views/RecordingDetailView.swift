import CoreGraphics
import SwiftUI

// MARK: - Display Event (groups down/up pairs for readability)

struct DisplayEvent: Identifiable {
    enum Kind {
        case single(MacroEvent)
        case click(down: MacroEvent, up: MacroEvent)
        case keyPress(down: MacroEvent, up: MacroEvent)
    }

    let kind: Kind

    var id: UUID { primaryEvent.id }

    var primaryEvent: MacroEvent {
        switch kind {
        case .single(let e):         return e
        case .click(let d, _):       return d
        case .keyPress(let d, _):    return d
        }
    }

    var involvedIDs: Set<UUID> {
        switch kind {
        case .single(let e):            return [e.id]
        case .click(let d, let u):      return [d.id, u.id]
        case .keyPress(let d, let u):   return [d.id, u.id]
        }
    }

    var isMouseMove: Bool {
        if case .single(let e) = kind { return e.isMouseMove }
        return false
    }

    var icon: String {
        switch kind {
        case .single(let e): return e.typeIcon
        case .click(let d, _):
            return d.type == .mouseLeftDown ? "cursorarrow.click" : "contextualmenu.and.cursorarrow"
        case .keyPress(let d, _): return d.typeIcon
        }
    }

    var color: Color {
        switch kind {
        case .single(let e):    return e.typeColor
        case .click:            return .purple
        case .keyPress(let d, _): return d.typeColor
        }
    }

    var displayTitle: String {
        switch kind {
        case .single(let e): return e.displayTitle
        case .click(let d, _):
            return d.type == .mouseLeftDown ? "Left Click" : "Right Click"
        case .keyPress(let d, _):
            guard let code = d.keyCode else { return "Key" }
            return MacroEvent.keyCodeNames[code] ?? "Key \(code)"
        }
    }

    var displaySubtitle: String? {
        switch kind {
        case .single(let e):
            if e.type == .scrollWheel {
                return "Δx \(e.scrollDeltaX)  Δy \(e.scrollDeltaY)"
            }
            return nil
        case .click(let d, _):
            if let p = d.position { return "at (\(Int(p.x)), \(Int(p.y)))" }
            return nil
        case .keyPress(let d, _):
            let flags = CGEventFlags(rawValue: d.eventFlags)
            var mods: [String] = []
            if flags.contains(.maskCommand)   { mods.append("⌘") }
            if flags.contains(.maskShift)     { mods.append("⇧") }
            if flags.contains(.maskAlternate) { mods.append("⌥") }
            if flags.contains(.maskControl)   { mods.append("⌃") }
            return mods.isEmpty ? nil : mods.joined()
        }
    }

    var timestamp: TimeInterval { primaryEvent.timestamp }
}

private func makeDisplayEvents(_ events: [MacroEvent]) -> [DisplayEvent] {
    var result: [DisplayEvent] = []
    result.reserveCapacity(events.count)
    var i = 0
    while i < events.count {
        let e = events[i]
        if i + 1 < events.count {
            let next = events[i + 1]
            if e.type == .mouseLeftDown && next.type == .mouseLeftUp {
                result.append(DisplayEvent(kind: .click(down: e, up: next)))
                i += 2; continue
            }
            if e.type == .mouseRightDown && next.type == .mouseRightUp {
                result.append(DisplayEvent(kind: .click(down: e, up: next)))
                i += 2; continue
            }
            if e.type == .keyDown && next.type == .keyUp && e.keyCode == next.keyCode {
                result.append(DisplayEvent(kind: .keyPress(down: e, up: next)))
                i += 2; continue
            }
        }
        result.append(DisplayEvent(kind: .single(e)))
        i += 1
    }
    return result
}

// MARK: - Timeline Crop View

struct TimelineCropView: View {
    let duration: TimeInterval
    @Binding var startFraction: Double
    @Binding var endFraction: Double

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let w = max(geo.size.width, 1)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.primary.opacity(0.08))
                        .frame(height: 6)

                    if startFraction > 0 {
                        Rectangle()
                            .fill(Color.red.opacity(0.25))
                            .frame(width: startFraction * w, height: 6)
                    }

                    Rectangle()
                        .fill(Color.accentColor.opacity(0.35))
                        .frame(width: max(0, (endFraction - startFraction) * w), height: 6)
                        .offset(x: startFraction * w)

                    if endFraction < 1 {
                        Rectangle()
                            .fill(Color.red.opacity(0.25))
                            .frame(width: max(0, (1 - endFraction) * w), height: 6)
                            .offset(x: endFraction * w)
                    }

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 4, height: 22)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                        .position(x: startFraction * w, y: 11)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .named("cropTrack"))
                                .onChanged { val in
                                    startFraction = max(0, min(val.location.x / w, endFraction - 0.02))
                                }
                        )

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 4, height: 22)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                        .position(x: endFraction * w, y: 11)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .named("cropTrack"))
                                .onChanged { val in
                                    endFraction = max(startFraction + 0.02, min(val.location.x / w, 1.0))
                                }
                        )
                }
            }
            .frame(height: 22)
            .coordinateSpace(.named("cropTrack"))

            HStack {
                Text(String(format: "%.2fs", startFraction * duration))
                    .foregroundStyle(.tint)
                Spacer()
                Text(String(format: "keep  %.2fs – %.2fs", startFraction * duration, endFraction * duration))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.2fs", endFraction * duration))
                    .foregroundStyle(.tint)
            }
            .font(.caption2.monospacedDigit())
        }
    }
}

// MARK: - Actions Panel

struct ActionsPanel: View {
    @Binding var recording: MacroRecording
    @Environment(EventPlayer.self) var player

    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var cropMode = false
    @State private var cropStart: Double = 0
    @State private var cropEnd: Double = 1

    private var displayEvents: [DisplayEvent] {
        makeDisplayEvents(recording.events)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if cropMode {
                cropBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Divider()
            eventList
        }
        .background(Color(red: 0.929, green: 0.906, blue: 0.859))
        .animation(.easeInOut(duration: 0.2), value: cropMode)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                if isEditingName {
                    TextField("Name", text: $editedName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(red: 0.239, green: 0.310, blue: 0.369))
                        .onSubmit { commitName() }
                        .onAppear { editedName = recording.name }
                } else {
                    Text(recording.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(red: 0.239, green: 0.310, blue: 0.369))
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            editedName = recording.name
                            isEditingName = true
                        }
                }
                Text("\(recording.events.count) actions")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)
            }
            Spacer()

            Button {
                if cropMode {
                    withAnimation { cropMode = false }
                } else {
                    cropStart = 0; cropEnd = 1
                    withAnimation { cropMode = true }
                }
            } label: {
                Image(systemName: cropMode ? "xmark.circle.fill" : "crop")
                    .font(.system(size: 13))
                    .foregroundStyle(cropMode ? Color.secondary : Color(red: 0.239, green: 0.310, blue: 0.369).opacity(0.6))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .help(cropMode ? "Cancel Crop" : "Crop Recording")
        }
        .padding(.top, 18)
        .padding(.trailing, 24)
        .padding(.bottom, 10)
        .padding(.leading, 24)
    }

    // MARK: - Crop Bar

    private var cropBar: some View {
        VStack(spacing: 10) {
            TimelineCropView(
                duration: recording.duration,
                startFraction: $cropStart,
                endFraction: $cropEnd
            )

            HStack {
                Text("\(Int(round((cropEnd - cropStart) * Double(recording.events.count)))) events kept")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Apply Crop", action: applyCrop)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    // MARK: - Event List

    private var eventList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(displayEvents.enumerated()), id: \.element.id) { index, de in
                    let isActive = de.involvedIDs.contains { $0 == player.currentEventID }
                    let outsideCrop = cropMode && (
                        de.timestamp < cropStart * recording.duration ||
                        de.timestamp > cropEnd * recording.duration
                    )

                    EventRowView(step: index + 1, displayEvent: de, isActive: isActive, dimmed: outsideCrop)
                        .id(de.id)
                        .listRowInsets(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { deleteDisplayEvent(de) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: player.currentEventID) { _, id in
                guard let id else { return }
                if let de = displayEvents.first(where: { $0.involvedIDs.contains(id) }) {
                    withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo(de.id, anchor: .center) }
                }
            }
        }
    }

    // MARK: - Actions

    private func deleteDisplayEvent(_ de: DisplayEvent) {
        recording.events.removeAll { de.involvedIDs.contains($0.id) }
        try? recording.save()
    }

    private func applyCrop() {
        let startT = cropStart * recording.duration
        let endT = cropEnd * recording.duration
        let kept = recording.events.filter { $0.timestamp >= startT && $0.timestamp <= endT }
        let offset = kept.first?.timestamp ?? 0
        recording.events = kept.map { e in
            MacroEvent(
                type: e.type,
                timestamp: e.timestamp - offset,
                position: e.position,
                keyCode: e.keyCode,
                eventFlags: e.eventFlags,
                scrollDeltaX: e.scrollDeltaX,
                scrollDeltaY: e.scrollDeltaY,
                mouseButton: e.mouseButton
            )
        }
        recording.duration = recording.events.last?.timestamp ?? 0
        try? recording.save()
        withAnimation { cropMode = false }
    }

    private func commitName() {
        if !editedName.isEmpty {
            recording.name = editedName
            try? recording.save()
        }
        isEditingName = false
    }
}

// MARK: - Event Row

struct EventRowView: View {
    let step: Int
    let displayEvent: DisplayEvent
    let isActive: Bool
    let dimmed: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text("\(step)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 22, height: 22)
                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                .fixedSize()

            Image(systemName: displayEvent.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(displayEvent.color)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 1) {
                Text(displayEvent.displayTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(red: 0.239, green: 0.310, blue: 0.369))
                    .lineLimit(1)

                if let subtitle = displayEvent.displaySubtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.accentColor)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                if isActive {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 5, height: 5)
                }
                Text(String(format: "%.1fs", displayEvent.timestamp))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color(red: 0.682, green: 0.741, blue: 0.792).opacity(0.2), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive
                    ? Color.accentColor.opacity(0.25)
                    : Color(red: 1.0, green: 0.973, blue: 0.914))
                .shadow(color: Color.black.opacity(0.2), radius: 1.5, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isActive
                        ? Color.accentColor.opacity(0.6)
                        : Color(red: 0.682, green: 0.741, blue: 0.792).opacity(0.4),
                    lineWidth: 1
                )
        )
        .opacity(dimmed ? 0.35 : 1.0)
    }
}

// MARK: - Empty State

struct EmptyActionsView: View {
    var body: some View {
        ContentUnavailableView(
            "No Recording Selected",
            systemImage: "record.circle",
            description: Text("Select a recording from the sidebar, or press Record to capture new inputs.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.929, green: 0.906, blue: 0.859))
    }
}
