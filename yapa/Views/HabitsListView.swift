import SwiftUI
import SwiftData

struct HabitsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]

    @State private var showCreateHabit = false
    @State private var showReorder = false

    private var activeHabits: [Habit] {
        habits.filter { !$0.isArchived }
    }

    private var archivedHabits: [Habit] {
        habits.filter { $0.isArchived }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if activeHabits.isEmpty && archivedHabits.isEmpty {
                        EmptyStateView(
                            icon: "list.bullet.clipboard",
                            title: "No habits yet",
                            subtitle: "Create your first habit to start tracking your progress.",
                            buttonTitle: "Create Habit",
                            action: { showCreateHabit = true }
                        )
                        .frame(minHeight: 400)
                    } else {
                        if !activeHabits.isEmpty {
                            habitsGrid(title: "Active", habits: activeHabits)
                        }
                        if !archivedHabits.isEmpty {
                            habitsGrid(title: "Archived", habits: archivedHabits)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if activeHabits.count > 1 {
                        Button { showReorder = true } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
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
            .sheet(isPresented: $showReorder) {
                ReorderHabitsView()
            }
        }
    }

    private func habitsGrid(title: String, habits: [Habit]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(habits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                        habitTile(habit)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func habitTile(_ habit: Habit) -> some View {
        let accentColor = Color(hex: habit.colorHex)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(habit.emoji)
                    .font(.system(size: 28))

                Spacer()

                if habit.currentStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(habit.currentStreak)")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                    }
                }
            }

            Text(habit.name)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            let rate = Int(habit.completionRate * 100)
            HStack(spacing: 6) {
                ProgressView(value: min(habit.completionRate, 1.0))
                    .tint(accentColor)

                Text("\(rate)%")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(minHeight: 130)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

// MARK: - Reorder Sheet

struct ReorderHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]

    @State private var orderedHabits: [Habit] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(orderedHabits) { habit in
                    HStack(spacing: 14) {
                        Text(habit.emoji)
                            .font(.system(size: 24))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: habit.colorHex).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        Text(habit.name)
                            .font(.system(.body, design: .rounded, weight: .medium))

                        Spacer()

                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onMove(perform: moveHabit)
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Reorder Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveOrder()
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                }
            }
            .onAppear {
                orderedHabits = habits
            }
        }
    }

    private func moveHabit(from source: IndexSet, to destination: Int) {
        orderedHabits.move(fromOffsets: source, toOffset: destination)
        AppSettings.shared.haptic(.light)
    }

    private func saveOrder() {
        for (index, habit) in orderedHabits.enumerated() {
            habit.sortOrder = index
        }
        try? modelContext.save()
    }
}
