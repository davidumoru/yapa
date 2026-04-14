import SwiftUI
import SwiftData

struct HabitsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var showCreateHabit = false

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
                ProgressView(value: habit.completionRate)
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
