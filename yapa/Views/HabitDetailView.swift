import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var habit: Habit

    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false

    private var accentColor: Color { Color(hex: habit.colorHex) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statsSection
                heatmapSection
                recentActivitySection
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { toggleTodayCompletion() } label: {
                        Label(
                            habit.isCompletedToday ? "Unmark today" : "Mark today complete",
                            systemImage: habit.isCompletedToday ? "xmark.circle" : "checkmark.circle"
                        )
                    }

                    Button { showEditSheet = true } label: {
                        Label("Edit Habit", systemImage: "pencil")
                    }

                    Button { toggleArchive() } label: {
                        Label(
                            habit.isArchived ? "Unarchive" : "Archive",
                            systemImage: habit.isArchived ? "tray.and.arrow.up" : "archivebox"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Habit", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            CreateHabitView(habitToEdit: habit)
        }
        .alert("Delete Habit?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { deleteHabit() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \"\(habit.name)\" and all its history.")
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(habit.emoji)
                .font(.system(size: 56))
                .frame(width: 88, height: 88)
                .background(accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text(habit.name)
                .font(.system(.title2, design: .rounded, weight: .bold))

            HStack(spacing: 16) {
                if habit.isArchived {
                    Text("Archived")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray4))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                if let daysRemaining = habit.daysRemaining {
                    Text("\(daysRemaining) days remaining")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    toggleTodayCompletion()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                    Text(habit.isCompletedToday ? "Completed today" : "Mark as done")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(habit.isCompletedToday ? accentColor : Color(.systemGray5))
                .foregroundStyle(habit.isCompletedToday ? .white : .primary)
                .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Current",
                value: "\(habit.currentStreak)",
                icon: "flame.fill",
                color: .orange
            )

            StatCard(
                title: "Best",
                value: "\(habit.bestStreak)",
                icon: "trophy.fill",
                color: .yellow
            )

            StatCard(
                title: "Rate",
                value: "\(Int(habit.completionRate * 100))%",
                icon: "chart.bar.fill",
                color: accentColor
            )
        }
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HeatmapCalendarView(habit: habit)
                .padding(16)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            let sortedEntries = habit.entries.sorted { $0.date > $1.date }.prefix(10)

            if sortedEntries.isEmpty {
                Text("No entries yet. Complete your first day!")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(accentColor)
                                .font(.system(size: 16))

                            Text(entry.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                .font(.system(.subheadline, design: .rounded))

                            Spacer()

                            if entry.date.isToday {
                                Text("Today")
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(accentColor.opacity(0.15))
                                    .foregroundStyle(accentColor)
                                    .clipShape(Capsule())
                            } else if entry.date.isYesterday {
                                Text("Yesterday")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if index < sortedEntries.count - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            }
        }
    }

    // MARK: - Actions

    private func toggleTodayCompletion() {
        let wasCompleted = habit.isCompletedToday
        if wasCompleted {
            if let entry = habit.entries.first(where: { $0.date.startOfDay == Date().startOfDay }) {
                modelContext.delete(entry)
            }
        } else {
            let entry = HabitEntry(date: Date(), habit: habit)
            modelContext.insert(entry)
        }
        try? modelContext.save()

        if wasCompleted {
            AppSettings.shared.haptic(.light)
        } else {
            AppSettings.shared.notificationHaptic(.success)
        }
    }

    private func toggleArchive() {
        habit.isArchived.toggle()
        try? modelContext.save()

        if habit.isArchived {
            NotificationManager.shared.removeReminders(for: habit)
        } else if !habit.reminderMinutes.isEmpty {
            Task {
                await NotificationManager.shared.requestAuthorization()
                NotificationManager.shared.scheduleReminders(for: habit)
            }
        }

        AppSettings.shared.haptic(.medium)
        dismiss()
    }

    private func deleteHabit() {
        NotificationManager.shared.removeReminders(for: habit)
        modelContext.delete(habit)
        try? modelContext.save()
        AppSettings.shared.notificationHaptic(.warning)
        dismiss()
    }
}
