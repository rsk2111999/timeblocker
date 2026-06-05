import AppKit
import UserNotifications

class BlockerService {
    static let shared = BlockerService()
    private var timer: Timer?
    private var config: ConfigManager { .shared }

    private init() {}

    func start() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appLaunched(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.scanRunning()
        }
    }

    func stop() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        timer?.invalidate()
        timer = nil
    }

    @objc private func appLaunched(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        checkAndKill(app)
    }

    private func scanRunning() {
        NSWorkspace.shared.runningApplications.forEach { checkAndKill($0) }
    }

    private func checkAndKill(_ app: NSRunningApplication) {
        guard config.isEffectivelyEnabled else { return }
        guard let bundleId = app.bundleIdentifier else { return }
        guard bundleId != Bundle.main.bundleIdentifier else { return }

        guard let blocked = config.blockedApps.first(where: { $0.bundleId == bundleId }) else { return }

        // Block if: within a scheduled window OR focus mode is active
        let shouldBlock = blocked.isCurrentlyBlocked || config.isFocusActive
        guard shouldBlock else { return }

        let reason = config.isFocusActive ? "focus" : "schedule"
        app.forceTerminate()
        StatsManager.shared.logBlock(appName: blocked.name, reason: reason)
        notify(appName: blocked.name, reason: config.isFocusActive ? "Focus mode is active." : "Blocked during this time.")
    }

    private func notify(appName: String, reason: String) {
        let content = UNMutableNotificationContent()
        content.title = "App Blocked"
        content.body  = "\(appName) — \(reason)"
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
