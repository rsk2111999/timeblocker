import Foundation
import AppKit

enum UpdateChecker {
    // ⚠️ Bump this every release — must match the GitHub tag (without "v")
    static let currentVersion = "1.0.1"

    private static let apiURL  = "https://api.github.com/repos/rsk2111999/timeblocker/releases/latest"
    private static let pageURL = URL(string: "https://github.com/rsk2111999/timeblocker/releases/latest")!

    /// Called on launch — silent (no alert if already up to date)
    static func checkSilently() {
        check(silent: true)
    }

    /// Called from "Check for Updates…" menu item — always shows result
    static func checkAndNotify() {
        check(silent: false)
    }

    private static func check(silent: Bool) {
        guard let url = URL(string: apiURL) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data,
                  let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag      = json["tag_name"] as? String,
                  let name     = json["name"] as? String,
                  let body     = json["body"] as? String else {
                if !silent { DispatchQueue.main.async { showError() } }
                return
            }

            let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag

            DispatchQueue.main.async {
                if isNewer(latest, than: currentVersion) {
                    showUpdateAlert(version: latest, title: name, notes: body)
                } else if !silent {
                    showUpToDate()
                }
            }
        }.resume()
    }

    private static func isNewer(_ latest: String, than current: String) -> Bool {
        latest.compare(current, options: .numeric) == .orderedDescending
    }

    private static func showUpdateAlert(version: String, title: String, notes: String) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText     = "Time Blocker \(version) is available"
        alert.informativeText = "You have \(currentVersion). Download the new version and drag it to /Applications to update.\n\nWhat's new:\n\(notes.prefix(300))"
        alert.alertStyle      = .informational
        alert.addButton(withTitle: "Download Update")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(pageURL)
        }
    }

    private static func showUpToDate() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText     = "You're up to date"
        alert.informativeText = "Time Blocker \(currentVersion) is the latest version."
        alert.alertStyle      = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static func showError() {
        let alert = NSAlert()
        alert.messageText     = "Couldn't check for updates"
        alert.informativeText = "Check your internet connection and try again."
        alert.alertStyle      = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
