import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var allHabits: [Habit]

    @State private var showCreateHabit = false
    @State private var showConfetti = false
    @State private var previousCompletedCount = -1

    private var todayHabits: [Habit] {
        allHabits.filter { $0.isScheduledToday }
    }

    private var completedCount: Int {
        todayHabits.filter { $0.isCompletedToday }.count
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        if !todayHabits.isEmpty {
                            progressSection
                            habitsSection
                        } else if allHabits.isEmpty {
                            EmptyStateView(
                                icon: "leaf.fill",
                                title: "Plant your first habit",
                                subtitle: "Start building positive routines by creating your first habit.",
                                buttonTitle: "Create Habit",
                                action: { showCreateHabit = true }
                            )
                            .frame(minHeight: 300)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.green)
                                Text("Nothing scheduled today")
                                    .font(.system(.headline, design: .rounded))
                                Text("Enjoy your rest day!")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .background(Color(.systemGroupedBackground))

                ConfettiOverlay(isActive: $showConfetti)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateHabit = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showCreateHabit) {
                CreateHabitView()
            }
            .onChange(of: completedCount) { oldValue, newValue in
                let total = todayHabits.count
                if total > 0 && newValue == total && oldValue < total {
                    showConfetti = true
                    AppSettings.shared.notificationHaptic(.success)
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.system(.title2, design: .rounded, weight: .bold))

            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var progressSection: some View {
        HStack(spacing: 12) {
            let progress = todayHabits.isEmpty ? 0.0 : Double(completedCount) / Double(todayHabits.count)

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progress)

                Text("\(completedCount)/\(todayHabits.count)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(completedCount == todayHabits.count ? "All done! 🎉" : "Keep going!")
                    .font(.system(.headline, design: .rounded))

                Text("\(todayHabits.count - completedCount) habit\(todayHabits.count - completedCount == 1 ? "" : "s") remaining")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Habits")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            ForEach(todayHabits) { habit in
                NavigationLink(destination: HabitDetailView(habit: habit)) {
                    HabitCard(habit: habit) {
                        toggleCompletion(for: habit)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func toggleCompletion(for habit: Habit) {
        if habit.isCompletedToday {
            if let entry = habit.entries.first(where: { $0.date.startOfDay == Date().startOfDay }) {
                modelContext.delete(entry)
            }
        } else {
            let entry = HabitEntry(date: Date(), habit: habit)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}
