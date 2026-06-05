import Foundation
import Combine
import CryptoKit

class ConfigManager: ObservableObject {
    static let shared = ConfigManager()

    @Published var blockedApps: [BlockedApp] = []
    @Published var isEnabled: Bool = true
    @Published var pauseUntil: Date? = nil
    @Published var focusUntil: Date? = nil
    @Published var passwordHash: String = ""

    private var configURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("TimeBlocker")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }

    private struct Config: Codable {
        var isEnabled: Bool
        var pauseUntil: Date?
        var focusUntil: Date?
        var passwordHash: String?
        var blockedApps: [BlockedApp]
    }

    private init() { load() }

    func verifyPassword(_ input: String) -> Bool {
        guard !passwordHash.isEmpty else { return true }
        let hash = SHA256.hash(data: Data(input.utf8))
        let hex  = hash.compactMap { String(format: "%02x", $0) }.joined()
        return hex == passwordHash
    }

    var isEffectivelyEnabled: Bool {
        guard isEnabled else { return false }
        if let until = pauseUntil, Date() < until { return false }
        return true
    }

    var isFocusActive: Bool {
        guard let until = focusUntil else { return false }
        return Date() < until
    }

    func load() {
        guard let data = try? Data(contentsOf: configURL),
              let c = try? JSONDecoder().decode(Config.self, from: data) else { return }
        isEnabled    = c.isEnabled
        pauseUntil   = c.pauseUntil
        focusUntil   = c.focusUntil
        passwordHash = c.passwordHash ?? ""
        blockedApps  = c.blockedApps
    }

    func save() {
        let c = Config(isEnabled: isEnabled, pauseUntil: pauseUntil, focusUntil: focusUntil,
                       passwordHash: passwordHash.isEmpty ? nil : passwordHash,
                       blockedApps: blockedApps)
        try? JSONEncoder().encode(c).write(to: configURL)
    }

    func startFocus(for duration: TimeInterval) {
        focusUntil = Date().addingTimeInterval(duration)
        pauseUntil = nil
        save()
        StatsManager.shared.logFocusStart()
    }

    func endFocus() {
        focusUntil = nil
        save()
        StatsManager.shared.logFocusEnd()
    }

    func add(_ app: BlockedApp) {
        blockedApps.append(app)
        save()
    }

    func remove(id: UUID) {
        blockedApps.removeAll { $0.id == id }
        save()
    }

    func update(_ app: BlockedApp) {
        guard let i = blockedApps.firstIndex(where: { $0.id == app.id }) else { return }
        blockedApps[i] = app
        save()
    }

    func pause(until date: Date) {
        pauseUntil = date
        save()
    }

    func resume() {
        pauseUntil = nil
        save()
    }
}
