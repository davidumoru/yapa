import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Provider

struct HabitWidgetProvider: TimelineProvider {
    let modelContainer: ModelContainer = {
        try! ModelContainer(for: Habit.self, HabitEntry.self)
    }()

    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(
            date: Date(),
            habits: [
                .init(name: "Meditate", emoji: "🧘", colorHex: "AF52DE", isCompleted: true, streak: 12),
                .init(name: "Exercise", emoji: "🏃", colorHex: "FF9500", isCompleted: false, streak: 5),
                .init(name: "Read", emoji: "📚", colorHex: "007AFF", isCompleted: false, streak: 3),
            ],
            completedCount: 1,
            totalCount: 3
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> Void) {
        completion(buildEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> Void) {
        let entry = buildEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    @MainActor
    private func buildEntry() -> HabitWidgetEntry {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)]
        )

        guard let habits = try? context.fetch(descriptor) else {
            return HabitWidgetEntry(date: Date(), habits: [], completedCount: 0, totalCount: 0)
        }

        let todayHabits = habits.filter { $0.isScheduledToday }
        let widgetHabits = todayHabits.prefix(6).map { habit in
            WidgetHabit(
                name: habit.name,
                emoji: habit.emoji,
                colorHex: habit.colorHex,
                isCompleted: habit.isCompletedToday,
                streak: habit.currentStreak
            )
        }

        return HabitWidgetEntry(
            date: Date(),
            habits: widgetHabits,
            completedCount: todayHabits.filter { $0.isCompletedToday }.count,
            totalCount: todayHabits.count
        )
    }
}

// MARK: - Data types

struct WidgetHabit: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let colorHex: String
    let isCompleted: Bool
    let streak: Int
}

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabit]
    let completedCount: Int
    let totalCount: Int
}

// MARK: - Widget Views

struct HabitWidgetSmallView: View {
    let entry: HabitWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(Color(hex: "34C759"))
            }

            if entry.habits.isEmpty {
                Spacer()
                Text("No habits today")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.habits.prefix(4)) { habit in
                    HStack(spacing: 6) {
                        Text(habit.emoji)
                            .font(.system(size: 14))

                        Text(habit.name)
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundStyle(
                                habit.isCompleted ? Color(hex: habit.colorHex) : Color(.systemGray4)
                            )
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct HabitWidgetMediumView: View {
    let entry: HabitWidgetEntry

    private var progress: Double {
        entry.totalCount == 0 ? 0 : Double(entry.completedCount) / Double(entry.totalCount)
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Today")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)

                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 5)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color(hex: "34C759"),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(entry.completedCount)/\(entry.totalCount)")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                }
                .frame(width: 52, height: 52)

                if entry.completedCount == entry.totalCount && entry.totalCount > 0 {
                    Text("All done! 🎉")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                } else {
                    Text("\(entry.totalCount - entry.completedCount) left")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.habits.prefix(5)) { habit in
                    HStack(spacing: 8) {
                        Text(habit.emoji)
                            .font(.system(size: 16))

                        Text(habit.name)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .lineLimit(1)

                        Spacer()

                        if habit.streak > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.orange)
                                Text("\(habit.streak)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }
                        }

                        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(
                                habit.isCompleted ? Color(hex: habit.colorHex) : Color(.systemGray4)
                            )
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Widget Configuration

struct yapaWidget: Widget {
    let kind: String = "yapaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitWidgetProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Habits")
        .description("Track your daily habit progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HabitWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            HabitWidgetSmallView(entry: entry)
        case .systemMedium:
            HabitWidgetMediumView(entry: entry)
        default:
            HabitWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct yapaWidgetBundle: WidgetBundle {
    var body: some Widget {
        yapaWidget()
    }
}
