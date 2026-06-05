import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject private var config = ConfigManager.shared

    var body: some View {
        Text(statusText)
            .foregroundStyle(.secondary)

        Divider()

        // Focus mode
        if config.isFocusActive {
            // During focus: end is password-gated, pause is hidden entirely
            Button("🔒 End Focus Early… (\(focusRemainingText) left)") {
                askPassword { config.endFocus() }
            }
        } else {
            Menu("🎯 Focus for…") {
                Button("30 minutes") { config.startFocus(for: 30 * 60) }
                Button("45 minutes") { config.startFocus(for: 45 * 60) }
                Button("1 hour")     { config.startFocus(for: 60 * 60) }
                Button("90 minutes") { config.startFocus(for: 90 * 60) }
                Button("2 hours")    { config.startFocus(for: 2 * 60 * 60) }
            }

            Divider()

            // Pause and toggle only visible outside focus mode
            Toggle("Enable Blocking", isOn: Binding(
                get: { config.isEnabled },
                set: { config.isEnabled = $0; config.save() }
            ))

            if config.isEffectivelyEnabled {
                Menu("Pause for…") {
                    Button("30 minutes")     { config.pause(until: Date().addingTimeInterval(1800)) }
                    Button("1 hour")         { config.pause(until: Date().addingTimeInterval(3600)) }
                    Button("2 hours")        { config.pause(until: Date().addingTimeInterval(7200)) }
                    Button("Until tomorrow") {
                        config.pause(until: Calendar.current.startOfDay(for: Date().addingTimeInterval(86400)))
                    }
                }
            } else if config.pauseUntil != nil {
                Button("Resume Now") { config.resume() }
            }
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
            SettingsWindowController.shared.show()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("This Week's Summary") {
            WeeklySummaryWindowController.shared.show()
        }

        Button("Check for Updates…") {
            UpdateChecker.checkAndNotify()
        }

        Divider()

        Button("Quit Time Blocker") { NSApp.terminate(nil) }
    }

    // MARK: - Password gate

    private func askPassword(onSuccess: @escaping () -> Void) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText      = "Password Required"
        alert.informativeText  = "Enter the password to end focus mode early."
        alert.alertStyle       = .warning
        if let icon = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil) {
            alert.icon = icon
        }

        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.placeholderString = "Password"
        alert.accessoryView = field
        alert.addButton(withTitle: "Unlock")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        if config.verifyPassword(field.stringValue) {
            onSuccess()
        } else {
            let err = NSAlert()
            err.messageText     = "Wrong Password"
            err.informativeText = "Stay focused! 💪"
            err.alertStyle      = .critical
            err.runModal()
        }
    }

    // MARK: - Helpers

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
        let mins = Int(max(0, until.timeIntervalSinceNow) / 60)
        let hrs  = mins / 60
        return hrs > 0 ? "\(hrs)h \(mins % 60)m" : "\(mins)m"
    }
}
