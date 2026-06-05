import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private init() {
        let hosting = NSHostingController(rootView: SettingsView())
        let window  = NSWindow(contentViewController: hosting)
        window.title        = "Monk Mode — Settings"
        window.styleMask    = [.titled, .closable, .resizable, .miniaturizable]
        window.setContentSize(NSSize(width: 640, height: 440))
        window.minSize      = NSSize(width: 520, height: 360)
        window.center()
        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) { nil }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        if !(window?.isVisible ?? false) { window?.center() }
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Nothing to clean up — singleton stays alive
    }
}
