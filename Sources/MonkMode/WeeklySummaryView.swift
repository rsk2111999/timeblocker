import SwiftUI

struct WeeklySummaryView: View {
    let stats: WeeklyStats
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text("📊 Your Week in Focus")
                    .font(.title2).bold()
                Text(weekRangeString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.accentColor.opacity(0.08))

            Divider()

            // Big three stats
            HStack(spacing: 0) {
                statBox(
                    value: String(format: "%.1f", stats.focusHours),
                    unit: "hrs",
                    label: "Focus time",
                    icon: "🎯"
                )
                Divider().frame(height: 80)
                statBox(
                    value: "\(stats.focusCount)",
                    unit: "sessions",
                    label: "Focus sessions",
                    icon: "⚡️"
                )
                Divider().frame(height: 80)
                statBox(
                    value: "\(stats.totalBlocks)",
                    unit: "times",
                    label: "Apps blocked",
                    icon: "🚫"
                )
            }
            .padding(.vertical, 8)

            Divider()

            // App breakdown
            if !stats.byApp.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Most blocked apps")
                        .font(.headline)
                        .padding(.bottom, 2)

                    ForEach(stats.byApp.prefix(5), id: \.name) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text("\(item.count)×")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            // Bar
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.accentColor)
                                .frame(width: barWidth(for: item.count), height: 8)
                        }
                    }
                }
                .padding()
            } else {
                Text("No blocks this week — nice schedule! 👏")
                    .foregroundStyle(.secondary)
                    .padding()
            }

            // Peak hour
            if let peak = stats.peakHour {
                Divider()
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("Most tempted at \(hourString(peak))")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.vertical, 10)
            }

            Divider()

            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
                .padding()
        }
        .frame(width: 400)
    }

    // MARK: - Sub-views

    private func statBox(value: String, unit: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.title)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 32, weight: .bold, design: .rounded))
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    private var weekRangeString: String {
        let end   = Date()
        let start = end.addingTimeInterval(-7 * 86400)
        let fmt   = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: start)) – \(fmt.string(from: end))"
    }

    private func barWidth(for count: Int) -> CGFloat {
        let max = stats.byApp.first?.count ?? 1
        return CGFloat(count) / CGFloat(max) * 80
    }

    private func hourString(_ hour: Int) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "ha"
        var comps = DateComponents(); comps.hour = hour
        guard let date = Calendar.current.date(from: comps) else { return "\(hour):00" }
        return fmt.string(from: date).lowercased()
    }
}
