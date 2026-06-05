import SwiftUI

struct SettingsView: View {
    @ObservedObject private var config = ConfigManager.shared
    @State private var selectedId: UUID?
    @State private var showingAddApp = false

    private var selectedApp: Binding<BlockedApp>? {
        guard let id = selectedId,
              let idx = config.blockedApps.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.config.blockedApps[idx] },
            set: { self.config.blockedApps[idx] = $0; self.config.save() }
        )
    }

    var body: some View {
        HSplitView {
            appListPanel
            if let app = selectedApp {
                TimeWindowEditor(app: app)
            } else {
                emptyState
            }
        }
        .frame(minWidth: 620, minHeight: 420)
        .onChange(of: config.blockedApps) { apps in
            if let id = selectedId, !apps.contains(where: { $0.id == id }) {
                selectedId = nil
            }
        }
        .sheet(isPresented: $showingAddApp) {
            AddAppSheet { newApp in
                config.add(newApp)
                selectedId = newApp.id
            }
        }
    }

    private var appListPanel: some View {
        VStack(spacing: 0) {
            List(config.blockedApps, selection: $selectedId) { app in
                HStack(spacing: 8) {
                    Image(systemName: app.isCurrentlyBlocked ? "xmark.circle.fill" : "circle.dashed")
                        .foregroundStyle(app.isCurrentlyBlocked ? .red : .secondary)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name)
                        Text("\(app.timeWindows.count) window\(app.timeWindows.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(app.id)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200, maxWidth: 250)

            Divider()

            HStack(spacing: 0) {
                Button { showingAddApp = true } label: {
                    Image(systemName: "plus").frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)

                Button {
                    if let id = selectedId { config.remove(id: id) }
                } label: {
                    Image(systemName: "minus").frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .disabled(selectedId == nil)

                Spacer()
            }
            .padding(.horizontal, 4)
            .frame(height: 32)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("Select an app to edit its schedule")
                .foregroundStyle(.secondary)
            Button("Add App…") { showingAddApp = true }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Time window editor

struct TimeWindowEditor: View {
    @Binding var app: BlockedApp

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.headline)
                Text("Block during these times")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            if app.timeWindows.isEmpty {
                Spacer()
                Text("No windows set — app will never be blocked.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach($app.timeWindows) { $window in
                            TimeWindowRow(window: $window) {
                                app.timeWindows.removeAll { $0.id == window.id }
                            }
                        }
                    }
                    .padding()
                }
            }

            Divider()

            Button {
                app.timeWindows.append(TimeWindow(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0))
            } label: {
                Label("Add Time Window", systemImage: "plus.circle")
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct TimeWindowRow: View {
    @Binding var window: TimeWindow
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("From").foregroundStyle(.secondary).frame(width: 36, alignment: .trailing)

            hourPicker($window.startHour)
            colonSep()
            minutePicker($window.startMinute)

            Text("to").foregroundStyle(.secondary).padding(.horizontal, 4)

            hourPicker($window.endHour)
            colonSep()
            minutePicker($window.endMinute)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash").foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func colonSep() -> some View { Text(":").foregroundStyle(.secondary) }

    private func hourPicker(_ value: Binding<Int>) -> some View {
        Picker("", selection: value) {
            ForEach(0..<24, id: \.self) { h in Text(String(format: "%02d", h)).tag(h) }
        }
        .labelsHidden().frame(width: 56)
    }

    private func minutePicker(_ value: Binding<Int>) -> some View {
        Picker("", selection: value) {
            ForEach([0, 15, 30, 45], id: \.self) { m in Text(String(format: "%02d", m)).tag(m) }
        }
        .labelsHidden().frame(width: 56)
    }
}

// MARK: - Add app sheet

struct AddAppSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (BlockedApp) -> Void

    @State private var search = ""
    @State private var apps: [(name: String, bundleId: String, path: String)] = []
    @State private var selected: String?
    @State private var loading = true

    private var filtered: [(name: String, bundleId: String, path: String)] {
        search.isEmpty ? apps : apps.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add App to Block").font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            TextField("Search…", text: $search)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal).padding(.vertical, 8)

            if loading {
                ProgressView("Loading installed apps…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filtered, id: \.bundleId, selection: $selected) { app in
                    HStack(spacing: 8) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                            .resizable().frame(width: 20, height: 20)
                        Text(app.name)
                    }
                    .tag(app.bundleId)
                }
                .listStyle(.plain)
            }

            Divider()

            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") {
                    if let id = selected, let a = apps.first(where: { $0.bundleId == id }) {
                        onAdd(BlockedApp(
                            name: a.name,
                            bundleId: a.bundleId,
                            timeWindows: [TimeWindow(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0)]
                        ))
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selected == nil)
            }
            .padding()
        }
        .frame(width: 380, height: 480)
        .onAppear { scanApps() }
    }

    private func scanApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            var result: [(name: String, bundleId: String, path: String)] = []
            let dirs = ["/Applications", "/System/Applications",
                        "/System/Applications/Utilities", "\(NSHomeDirectory())/Applications"]

            for dir in dirs {
                guard let items = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
                for item in items where item.hasSuffix(".app") {
                    let path = "\(dir)/\(item)"
                    guard let bundle = Bundle(path: path),
                          let bid = bundle.bundleIdentifier else { continue }
                    let info = bundle.infoDictionary
                    let name = info?["CFBundleDisplayName"] as? String
                             ?? info?["CFBundleName"] as? String
                             ?? String(item.dropLast(4))
                    result.append((name: name, bundleId: bid, path: path))
                }
            }

            let sorted = result.sorted { $0.name.lowercased() < $1.name.lowercased() }
            DispatchQueue.main.async { apps = sorted; loading = false }
        }
    }
}
