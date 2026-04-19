import SwiftUI

// MARK: - Display Event (groups down/up pairs for readability)

struct DisplayEvent: Identifiable {
    enum Kind {
        case single(MacroEvent)
        case click(down: MacroEvent, up: MacroEvent)    // left or right click pair
        case keyPress(down: MacroEvent, up: MacroEvent) // key down + up pair
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
            let name = d.type == .mouseLeftDown ? "Left Click" : "Right Click"
            if let p = d.position { return "\(name)  (\(Int(p.x)), \(Int(p.y)))" }
            return name
        case .keyPress(let d, _):
            guard let code = d.keyCode else { return "Key" }
            return MacroEvent.keyCodeNames[code] ?? "Key \(code)"
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
                    // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.primary.opacity(0.08))
                        .frame(height: 6)

                    // Trim region — left (will be deleted)
                    if startFraction > 0 {
                        Rectangle()
                            .fill(Color.red.opacity(0.25))
                            .frame(width: startFraction * w, height: 6)
                    }

                    // Keep region
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.35))
                        .frame(width: max(0, (endFraction - startFraction) * w), height: 6)
                        .offset(x: startFraction * w)

                    // Trim region — right (will be deleted)
                    if endFraction < 1 {
                        Rectangle()
                            .fill(Color.red.opacity(0.25))
                            .frame(width: max(0, (1 - endFraction) * w), height: 6)
                            .offset(x: endFraction * w)
                    }

                    // Start handle
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

                    // End handle
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
        .animation(.easeInOut(duration: 0.2), value: cropMode)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                if isEditingName {
                    TextField("Name", text: $editedName)
                        .textFieldStyle(.plain)
                        .font(.headline.bold())
                        .fontDesign(.rounded)
                        .onSubmit { commitName() }
                        .onAppear { editedName = recording.name }
                } else {
                    Text(recording.name)
                        .font(.headline.bold())
                        .fontDesign(.rounded)
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            editedName = recording.name
                            isEditingName = true
                        }
                }
                Text("\(recording.events.count) events · \(recording.duration.mmss)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(recording.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Button {
                if cropMode {
                    withAnimation { cropMode = false }
                } else {
                    cropStart = 0; cropEnd = 1
                    withAnimation { cropMode = true }
                }
            } label: {
                Image(systemName: cropMode ? "xmark.circle.fill" : "crop")
                    .foregroundStyle(cropMode ? Color.secondary : Color.primary)
            }
            .buttonStyle(.plain)
            .help(cropMode ? "Cancel Crop" : "Crop Recording")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
                ForEach(displayEvents) { de in
                    let isActive = de.involvedIDs.contains { $0 == player.currentEventID }
                    let outsideCrop = cropMode && (
                        de.timestamp < cropStart * recording.duration ||
                        de.timestamp > cropEnd * recording.duration
                    )

                    EventRowView(displayEvent: de, isActive: isActive, dimmed: outsideCrop)
                        .id(de.id)
                        .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                        .listRowBackground(isActive ? de.color.opacity(0.12) : Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { deleteDisplayEvent(de) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
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
    let displayEvent: DisplayEvent
    let isActive: Bool
    let dimmed: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: displayEvent.icon)
                .font(.caption.bold())
                .foregroundStyle(displayEvent.color)
                .frame(width: 22, height: 22)
                .background(displayEvent.color.opacity(0.12), in: Circle())

            Text(displayEvent.displayTitle)
                .font(displayEvent.isMouseMove ? .caption.monospaced() : .callout.monospaced())
                .foregroundStyle(displayEvent.isMouseMove ? .secondary : .primary)
                .lineLimit(1)

            Spacer()

            Text(String(format: "%.2fs", displayEvent.timestamp))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, displayEvent.isMouseMove ? 2 : 4)
        .opacity(dimmed ? 0.3 : 1.0)
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
    }
}
