import SwiftUI

struct MenuBarView: View {
    @ObservedObject private var config = ConfigManager.shared

    var body: some View {
        Text(statusText)
            .foregroundStyle(.secondary)

        Divider()

        // Focus mode — force-block all configured apps right now
        if config.isFocusActive {
            Button("⏹ End Focus (\(focusRemainingText))") { config.endFocus() }
        } else {
            Menu("🎯 Focus for…") {
                Button("30 minutes") { config.startFocus(for: 30 * 60) }
                Button("45 minutes") { config.startFocus(for: 45 * 60) }
                Button("1 hour")     { config.startFocus(for: 60 * 60) }
                Button("90 minutes") { config.startFocus(for: 90 * 60) }
                Button("2 hours")    { config.startFocus(for: 2 * 60 * 60) }
            }
        }

        Divider()

        Toggle("Enable Blocking", isOn: Binding(
            get: { config.isEnabled },
            set: { config.isEnabled = $0; config.save() }
        ))

        if config.isEffectivelyEnabled {
            Menu("Pause for…") {
                Button("30 minutes")    { config.pause(until: Date().addingTimeInterval(1800)) }
                Button("1 hour")        { config.pause(until: Date().addingTimeInterval(3600)) }
                Button("2 hours")       { config.pause(until: Date().addingTimeInterval(7200)) }
                Button("Until tomorrow") {
                    let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
                    config.pause(until: tomorrow)
                }
            }
        } else if config.pauseUntil != nil {
            Button("Resume Now") { config.resume() }
        }

        Divider()

        if config.blockedApps.isEmpty {
            Text("No apps configured")
                .foregroundStyle(.tertiary)
        } else {
            ForEach(config.blockedApps) { app in
                Label(
                    app.isCurrentlyBlocked ? "\(app.name) — BLOCKED" : app.name,
                    systemImage: app.isCurrentlyBlocked ? "xmark.circle.fill" : "checkmark.circle"
                )
                .foregroundStyle(app.isCurrentlyBlocked ? .red : .primary)
            }
        }

        Divider()

        Button("Settings…") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }

        Button("Quit Time Blocker") { NSApp.terminate(nil) }
    }

    private var statusText: String {
        guard config.isEnabled else { return "Blocking disabled" }
        if config.isFocusActive {
            return "🎯 Focus mode · \(focusRemainingText) left"
        }
        if let until = config.pauseUntil, Date() < until {
            let fmt = RelativeDateTimeFormatter()
            fmt.unitsStyle = .abbreviated
            return "Paused · resumes \(fmt.localizedString(for: until, relativeTo: Date()))"
        }
        let n = config.blockedApps.filter { $0.isCurrentlyBlocked }.count
        return n > 0 ? "\(n) app\(n == 1 ? "" : "s") blocked now" : "Blocking active"
    }

    private var focusRemainingText: String {
        guard let until = config.focusUntil else { return "" }
        let secs = max(0, until.timeIntervalSinceNow)
        let mins = Int(secs / 60)
        let hrs  = mins / 60
        if hrs > 0 { return "\(hrs)h \(mins % 60)m" }
        return "\(mins)m"
    }
}
