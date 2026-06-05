import Foundation

// MARK: - Models

struct BlockEvent: Codable {
    var timestamp: Date
    var appName: String
    var reason: String          // "schedule" or "focus"
}

struct FocusSession: Codable {
    var start: Date
    var end: Date
    var minutes: Double { end.timeIntervalSince(start) / 60 }
}

struct WeeklyStats {
    var focusSessions: [FocusSession]
    var blockEvents: [BlockEvent]

    var focusHours: Double   { focusSessions.reduce(0) { $0 + $1.minutes } / 60 }
    var focusCount: Int      { focusSessions.count }
    var totalBlocks: Int     { blockEvents.count }

    var byApp: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: blockEvents, by: { $0.appName })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        return grouped.map { (name: $0.key, count: $0.value) }
    }

    var peakHour: Int? {
        guard !blockEvents.isEmpty else { return nil }
        let hours = blockEvents.map { Calendar.current.component(.hour, from: $0.timestamp) }
        return Dictionary(grouping: hours, by: { $0 }).max(by: { $0.value.count < $1.value.count })?.key
    }
}

// MARK: - Manager

class StatsManager {
    static let shared = StatsManager()

    private var blockEvents:   [BlockEvent]   = []
    private var focusSessions: [FocusSession] = []
    private var activeFocusStart: Date?

    private struct Store: Codable {
        var blockEvents: [BlockEvent]
        var focusSessions: [FocusSession]
    }

    private var storeURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("MonkMode")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("stats.json")
    }

    private init() { load() }

    // MARK: - Logging

    func logBlock(appName: String, reason: String) {
        blockEvents.append(BlockEvent(timestamp: Date(), appName: appName, reason: reason))
        save()
    }

    func logFocusStart() {
        activeFocusStart = Date()
    }

    func logFocusEnd() {
        guard let start = activeFocusStart else { return }
        focusSessions.append(FocusSession(start: start, end: Date()))
        activeFocusStart = nil
        save()
    }

    // MARK: - Stats

    func weeklyStats(for date: Date = Date()) -> WeeklyStats {
        let weekAgo = date.addingTimeInterval(-7 * 86400)
        return WeeklyStats(
            focusSessions: focusSessions.filter { $0.start >= weekAgo },
            blockEvents:   blockEvents.filter   { $0.timestamp >= weekAgo }
        )
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let s = try? JSONDecoder().decode(Store.self, from: data) else { return }
        blockEvents   = s.blockEvents
        focusSessions = s.focusSessions
    }

    private func save() {
        let s = Store(blockEvents: blockEvents, focusSessions: focusSessions)
        try? JSONEncoder().encode(s).write(to: storeURL)
    }

    // MARK: - Weekly trigger

    private let summaryKey = "lastSummaryShown"

    func checkAndShowWeeklySummary() {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // 1=Sun, 6=Fri, 7=Sat
        let hour    = cal.component(.hour, from: now)

        // Show Friday 6pm–11pm or Saturday 8am–11am
        let isTriggerTime = (weekday == 6 && hour >= 18) || (weekday == 7 && hour >= 8 && hour <= 11)
        guard isTriggerTime else { return }

        // Only once per week
        if let last = UserDefaults.standard.object(forKey: summaryKey) as? Date,
           cal.isDate(last, equalTo: now, toGranularity: .weekOfYear) { return }

        UserDefaults.standard.set(now, forKey: summaryKey)

        DispatchQueue.main.async {
            WeeklySummaryWindowController.shared.show()
        }
    }
}
