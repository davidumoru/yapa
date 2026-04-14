import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allHabits: [Habit]
    @Query private var allEntries: [HabitEntry]

    @Bindable private var settings = AppSettings.shared

    @State private var showResetConfirmation = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                notificationsSection
                preferencesSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .task { await checkNotificationStatus() }
            .alert("Reset All Data?", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) { resetAllData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all habits, entries, and history. This cannot be undone.")
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(url: url)
                }
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            ForEach(AppTheme.allCases) { theme in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        settings.theme = theme
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: theme.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(theme == settings.theme ? Color.accentColor : .secondary)
                            .frame(width: 28)

                        Text(theme.label)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.primary)

                        Spacer()

                        if theme == settings.theme {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            HStack {
                Label("Status", systemImage: "bell.badge.fill")
                    .font(.system(.body, design: .rounded))

                Spacer()

                Text(notificationStatusLabel)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(notificationStatusColor)
            }

            if notificationStatus == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open System Settings", systemImage: "gear")
                        .font(.system(.body, design: .rounded))
                }
            } else if notificationStatus == .notDetermined {
                Button {
                    Task {
                        await NotificationManager.shared.requestAuthorization()
                        await checkNotificationStatus()
                    }
                } label: {
                    Label("Enable Notifications", systemImage: "bell.fill")
                        .font(.system(.body, design: .rounded))
                }
            }
        } header: {
            Text("Notifications")
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    .font(.system(.body, design: .rounded))
            }
        } header: {
            Text("Preferences")
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            Button { exportData() } label: {
                Label("Export Data (CSV)", systemImage: "square.and.arrow.up")
                    .font(.system(.body, design: .rounded))
            }
            .disabled(allHabits.isEmpty)

            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("Reset All Data", systemImage: "trash")
                    .font(.system(.body, design: .rounded))
            }
            .disabled(allHabits.isEmpty)
        } header: {
            Text("Data")
        } footer: {
            Text("\(allHabits.count) habit\(allHabits.count == 1 ? "" : "s"), \(allEntries.count) total entr\(allEntries.count == 1 ? "y" : "ies")")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .font(.system(.body, design: .rounded))
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Build")
                    .font(.system(.body, design: .rounded))
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About")
        } footer: {
            Text("Made by David")
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
        }
    }

    // MARK: - Helpers

    private var notificationStatusLabel: String {
        switch notificationStatus {
        case .authorized: "Enabled"
        case .denied: "Disabled"
        case .provisional: "Provisional"
        case .notDetermined: "Not Set"
        case .ephemeral: "Ephemeral"
        @unknown default: "Unknown"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: .green
        case .denied: .red
        case .notDetermined: .secondary
        @unknown default: .secondary
        }
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationStatus = settings.authorizationStatus
        }
    }

    private func exportData() {
        var csv = "Habit,Emoji,Date,Completed At,Streak at Time\n"

        for habit in allHabits {
            let sorted = habit.entries.sorted { $0.date < $1.date }
            if sorted.isEmpty {
                csv += "\"\(habit.name)\",\(habit.emoji),—,—,0\n"
            } else {
                for entry in sorted {
                    let dateStr = entry.date.formatted(.dateTime.year().month().day())
                    let completedStr = entry.completedAt.formatted(.dateTime.year().month().day().hour().minute())
                    csv += "\"\(habit.name)\",\(habit.emoji),\(dateStr),\(completedStr),\(habit.currentStreak)\n"
                }
            }
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("yapa-export-\(Date().formatted(.dateTime.year().month().day())).csv")

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            exportURL = fileURL
            showExportSheet = true
        } catch {
            // silently fail
        }
    }

    private func resetAllData() {
        for habit in allHabits {
            NotificationManager.shared.removeReminders(for: habit)
            modelContext.delete(habit)
        }
        for entry in allEntries {
            modelContext.delete(entry)
        }
        try? modelContext.save()
        AppSettings.shared.notificationHaptic(.warning)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
