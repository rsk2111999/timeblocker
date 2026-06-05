import SwiftUI
import UserNotifications
import ServiceManagement

@main
struct TimeBlockerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Time Blocker", systemImage: "timer") {
            MenuBarView()
        }
        .menuBarExtraStyle(.menu)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
        BlockerService.shared.start()

        // Register as a login item (appears in System Settings → General → Login Items)
        try? SMAppService.mainApp.register()

        // Silently check for updates on every launch
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            UpdateChecker.checkSilently()
        }

        // Hourly check — shows weekly summary on Friday evening / Saturday morning
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            StatsManager.shared.checkAndShowWeeklySummary()
        }
        // Also check immediately on launch (catches missed Friday windows)
        StatsManager.shared.checkAndShowWeeklySummary()
    }

    func applicationWillTerminate(_ notification: Notification) {
        BlockerService.shared.stop()
    }
}
