import Foundation

struct TimeWindow: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int

    var displayString: String {
        let s = String(format: "%02d:%02d", startHour, startMinute)
        let e = String(format: "%02d:%02d", endHour, endMinute)
        return "\(s) – \(e)"
    }

    func isActive() -> Bool {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        guard let h = comps.hour, let m = comps.minute else { return false }
        let now   = h * 60 + m
        let start = startHour * 60 + startMinute
        let end   = endHour   * 60 + endMinute
        // Handle overnight windows (e.g. 22:00–06:00)
        return start < end ? (now >= start && now < end) : (now >= start || now < end)
    }
}

struct BlockedApp: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var bundleId: String
    var timeWindows: [TimeWindow]

    var isCurrentlyBlocked: Bool {
        timeWindows.contains { $0.isActive() }
    }
}
