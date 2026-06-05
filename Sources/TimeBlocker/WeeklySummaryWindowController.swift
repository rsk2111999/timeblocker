import AppKit
import SwiftUI

class WeeklySummaryWindowController: NSWindowController, NSWindowDelegate {
    static let shared = WeeklySummaryWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Weekly Summary"
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) { nil }

    func show() {
        let stats = StatsManager.shared.weeklyStats()
        let view  = WeeklySummaryView(stats: stats)
        window?.contentViewController = NSHostingController(rootView: view)
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
