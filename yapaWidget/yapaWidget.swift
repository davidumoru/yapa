import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Date Helpers (widget-isolated)

extension Date {
    fileprivate var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    fileprivate var weekday: Int { Calendar.current.component(.weekday, from: self) }
    fileprivate func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

// MARK: - SwiftData Models (widget-isolated copies)

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "🎯"
    var colorHex: String = "34C759"
    var scheduledWeekdays: [Int] = []
    var targetDays: Int = 0
    var reminderMinutes: [Int] = []
    var createdAt: Date = Date()
    var isArchived: Bool = false
    var sortOrder: Int = 0
    var graceDays: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry] = []

    init() {}

    func isScheduledOn(_ date: Date) -> Bool {
        if scheduledWeekdays.isEmpty { return true }
        return scheduledWeekdays.contains(date.weekday)
    }

    var isScheduledToday: Bool { isScheduledOn(Date()) }

    func isCompletedOn(_ date: Date) -> Bool {
        let target = date.startOfDay
        return entries.contains { $0.date.startOfDay == target }
    }

    var isCompletedToday: Bool { isCompletedOn(Date()) }

    private var completedDaySet: Set<Date> {
        Set(entries.map { $0.date.startOfDay })
    }

    var currentStreak: Int {
        let completed = completedDaySet
        guard !completed.isEmpty else { return 0 }
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        if !completed.contains(checkDate) {
            checkDate = checkDate.adding(days: -1)
        }
        var streak = 0
        var consecutiveMisses = 0
        let earliest = calendar.startOfDay(for: createdAt)
        while checkDate >= earliest {
            if isScheduledOn(checkDate) {
                if completed.contains(checkDate) {
                    streak += 1
                    consecutiveMisses = 0
                } else {
                    consecutiveMisses += 1
                    if consecutiveMisses > graceDays { break }
                }
            }
            checkDate = checkDate.adding(days: -1)
        }
        return streak
    }

    var bestStreak: Int {
        let completed = completedDaySet
        guard !completed.isEmpty else { return 0 }
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: createdAt)
        let today = calendar.startOfDay(for: Date())
        var current = 0
        var best = 0
        var consecutiveMisses = 0
        while checkDate <= today {
            if isScheduledOn(checkDate) {
                if completed.contains(checkDate) {
                    current += 1
                    consecutiveMisses = 0
                    best = max(best, current)
                } else {
                    consecutiveMisses += 1
                    if consecutiveMisses > graceDays {
                        current = 0
                        consecutiveMisses = 0
                    }
                }
            }
            checkDate = checkDate.adding(days: 1)
        }
        return best
    }

    var completionRate: Double {
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: createdAt)
        let today = calendar.startOfDay(for: Date())
        let completed = completedDaySet
        var scheduled = 0
        var done = 0
        while date <= today {
            if isScheduledOn(date) {
                scheduled += 1
                if completed.contains(date) { done += 1 }
            }
            date = date.adding(days: 1)
        }
        return scheduled == 0 ? 0 : Double(done) / Double(scheduled)
    }

    var totalCompletions: Int { entries.count }

    static let milestoneThresholds = [7, 21, 30, 60, 90, 180, 365]

    var nextMilestone: Int? {
        Self.milestoneThresholds.first { $0 > currentStreak }
    }
}

@Model
final class HabitEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var completedAt: Date = Date()
    var note: String = ""
    var habit: Habit?
    init() {}
}

// MARK: - Shared Model Container

enum WidgetData {
    static let container: ModelContainer = {
        let schema = Schema([Habit.self, HabitEntry.self])
        let config = ModelConfiguration("default")
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}

// MARK: - Day Status (for heatmaps)

enum DayStatus {
    case completed, missed, notScheduled, future
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - TODAY WIDGET
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
    let bestStreak: Int
    let last7Days: [Double]
}

private let accentGreen = Color(hex: "34C759")

// MARK: Today Widget Provider

struct HabitWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(
            date: Date(),
            habits: [
                .init(name: "Meditate", emoji: "🧘", colorHex: "AF52DE", isCompleted: true, streak: 12),
                .init(name: "Exercise", emoji: "🏃", colorHex: "FF9500", isCompleted: false, streak: 5),
                .init(name: "Read", emoji: "📚", colorHex: "007AFF", isCompleted: true, streak: 3),
                .init(name: "Journal", emoji: "📝", colorHex: "FF2D55", isCompleted: false, streak: 8),
            ],
            completedCount: 2, totalCount: 4, bestStreak: 12,
            last7Days: [1.0, 0.75, 1.0, 0.5, 1.0, 0.75, 0.25]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> Void) {
        Task { @MainActor in completion(buildEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> Void) {
        Task { @MainActor in
            let entry = buildEntry()
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    @MainActor
    private func buildEntry() -> HabitWidgetEntry {
        let ctx = WidgetData.container.mainContext
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)]
        )
        guard let habits = try? ctx.fetch(descriptor) else {
            return HabitWidgetEntry(date: Date(), habits: [], completedCount: 0, totalCount: 0, bestStreak: 0, last7Days: [])
        }

        let todayHabits = habits.filter { $0.isScheduledToday }
        let widgetHabits = todayHabits.prefix(6).map {
            WidgetHabit(name: $0.name, emoji: $0.emoji, colorHex: $0.colorHex,
                        isCompleted: $0.isCompletedToday, streak: $0.currentStreak)
        }
        let best = habits.map(\.currentStreak).max() ?? 0

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let last7 = (0..<7).reversed().map { i -> Double in
            let day = today.adding(days: -i)
            let scheduled = habits.filter { $0.isScheduledOn(day) }
            let completed = scheduled.filter { $0.isCompletedOn(day) }
            return scheduled.isEmpty ? 0 : Double(completed.count) / Double(scheduled.count)
        }

        return HabitWidgetEntry(
            date: Date(), habits: Array(widgetHabits),
            completedCount: todayHabits.filter(\.isCompletedToday).count,
            totalCount: todayHabits.count, bestStreak: best, last7Days: last7
        )
    }
}

// MARK: - Shared gradient background for Today widget

private struct TodayBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "3DD863"), location: 0),
                .init(color: Color(hex: "34C759"), location: 0.4),
                .init(color: Color(hex: "1B8C3A"), location: 1),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: Today Small

struct TodaySmallView: View {
    let entry: HabitWidgetEntry

    private var progress: Double {
        entry.totalCount == 0 ? 0 : Double(entry.completedCount) / Double(entry.totalCount)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(entry.date.formatted(.dateTime.day()))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                if entry.bestStreak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill").font(.system(size: 9))
                        Text("\(entry.bestStreak)").font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }

            Spacer(minLength: 4)

            ZStack {
                Circle().stroke(.white.opacity(0.12), lineWidth: 8)
                Circle().trim(from: 0, to: progress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: -1) {
                    Text("\(Int(progress * 100))")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("percent")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: 76, height: 76)

            Spacer(minLength: 4)

            HStack(spacing: 3) {
                ForEach(0..<7, id: \.self) { i in
                    let rate = i < entry.last7Days.count ? entry.last7Days[i] : 0
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(.white.opacity(rate > 0 ? 0.25 + rate * 0.75 : 0.08))
                        .frame(height: 5)
                }
            }
        }
        .containerBackground(for: .widget) { TodayBackground() }
    }
}

// MARK: Today Medium

struct TodayMediumView: View {
    let entry: HabitWidgetEntry

    private var progress: Double {
        entry.totalCount == 0 ? 0 : Double(entry.completedCount) / Double(entry.totalCount)
    }

    private var weekLabels: [String] {
        let today = Date().startOfDay
        return (0..<7).reversed().map { i in
            String(today.adding(days: -i).formatted(.dateTime.weekday(.narrow)))
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Left column: ring + week dots
            VStack(spacing: 10) {
                ZStack {
                    Circle().stroke(.white.opacity(0.12), lineWidth: 6)
                    Circle().trim(from: 0, to: progress)
                        .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: -1) {
                        Text("\(entry.completedCount)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        Text("of \(entry.totalCount)")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .frame(width: 64, height: 64)

                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { i in
                        let rate = i < entry.last7Days.count ? entry.last7Days[i] : 0
                        VStack(spacing: 2) {
                            Circle()
                                .fill(.white.opacity(rate > 0 ? 0.35 + rate * 0.65 : 0.1))
                                .frame(width: 8, height: 8)
                            Text(weekLabels[i])
                                .font(.system(size: 7, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }
                }
            }

            // Right column: habit list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(entry.completedCount == entry.totalCount && entry.totalCount > 0 ? "All done!" : "Today")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.white.opacity(0.75))
                    Spacer()
                    if entry.bestStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill").font(.system(size: 9)).foregroundStyle(.orange)
                            Text("\(entry.bestStreak)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                }
                .padding(.bottom, 6)

                if entry.habits.isEmpty {
                    Spacer()
                    Text("No habits today")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                } else {
                    ForEach(entry.habits.prefix(4)) { habit in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color(hex: habit.colorHex))
                                .frame(width: 3, height: 22)
                            Text(habit.emoji).font(.system(size: 14))
                            Text(habit.name)
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .foregroundStyle(.white).lineLimit(1)
                            Spacer()
                            if habit.streak > 0 {
                                Text("\(habit.streak)d")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(habit.isCompleted ? .white : .white.opacity(0.25))
                        }
                        .padding(.vertical, 3)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .containerBackground(for: .widget) { TodayBackground() }
    }
}

// MARK: Today Large

struct TodayLargeView: View {
    let entry: HabitWidgetEntry

    private var progress: Double {
        entry.totalCount == 0 ? 0 : Double(entry.completedCount) / Double(entry.totalCount)
    }

    private var weekLabels: [String] {
        let today = Date().startOfDay
        return (0..<7).reversed().map { i in
            String(today.adding(days: -i).formatted(.dateTime.weekday(.abbreviated)).prefix(3))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date.formatted(.dateTime.weekday(.wide)))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(entry.date.formatted(.dateTime.month(.wide).day()))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                if entry.bestStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").font(.system(size: 11))
                        Text("\(entry.bestStreak) day streak")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(.bottom, 12)

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(entry.completedCount) of \(entry.totalCount) habits")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.12))
                        Capsule().fill(.white)
                            .frame(width: max(0, geo.size.width * progress))
                    }
                }
                .frame(height: 6)
            }
            .padding(.bottom, 14)

            // Habit list
            if entry.habits.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("No habits scheduled today")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entry.habits.prefix(6).enumerated()), id: \.element.id) { index, habit in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color(hex: habit.colorHex))
                                .frame(width: 3, height: 28)
                            Text(habit.emoji).font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(habit.name)
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundStyle(.white).lineLimit(1)
                                if habit.streak > 0 {
                                    Text("\(habit.streak) day streak")
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                            }
                            Spacer()
                            Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(habit.isCompleted ? .white : .white.opacity(0.25))
                        }
                        .padding(.vertical, 6)
                        if index < min(entry.habits.count, 6) - 1 {
                            Divider().background(.white.opacity(0.1))
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            // 7-day bar chart
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    let rate = i < entry.last7Days.count ? entry.last7Days[i] : 0
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(.white.opacity(rate > 0 ? 0.3 + rate * 0.7 : 0.08))
                            .frame(height: max(4, CGFloat(rate) * 32))
                        Text(weekLabels[i])
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 46)
        }
        .containerBackground(for: .widget) { TodayBackground() }
    }
}

// MARK: Today Widget Config

struct yapaWidget: Widget {
    let kind = "yapaWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitWidgetProvider()) { entry in
            TodayEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Habits")
        .description("Track your daily habit progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct TodayEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HabitWidgetEntry
    var body: some View {
        switch family {
        case .systemMedium: TodayMediumView(entry: entry)
        case .systemLarge:  TodayLargeView(entry: entry)
        default:            TodaySmallView(entry: entry)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - SINGLE HABIT WIDGET
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct SingleHabitEntry: TimelineEntry {
    let date: Date
    let habitName: String
    let habitEmoji: String
    let habitColorHex: String
    let isCompletedToday: Bool
    let currentStreak: Int
    let bestStreak: Int
    let completionRate: Double
    let totalCompletions: Int
    let last7Days: [DayStatus]
    let heatmapWeeks: [[DayStatus]] // 4 rows of 7
    let nextMilestone: Int?
    let isEmpty: Bool
}

private func emptySingleEntry() -> SingleHabitEntry {
    SingleHabitEntry(
        date: Date(), habitName: "", habitEmoji: "", habitColorHex: "34C759",
        isCompletedToday: false, currentStreak: 0, bestStreak: 0,
        completionRate: 0, totalCompletions: 0,
        last7Days: [], heatmapWeeks: [], nextMilestone: nil, isEmpty: true
    )
}

private func placeholderSingleEntry() -> SingleHabitEntry {
    SingleHabitEntry(
        date: Date(), habitName: "Meditate", habitEmoji: "🧘", habitColorHex: "AF52DE",
        isCompletedToday: true, currentStreak: 12, bestStreak: 15,
        completionRate: 0.85, totalCompletions: 47,
        last7Days: [.completed, .completed, .missed, .completed, .completed, .completed, .notScheduled],
        heatmapWeeks: [
            [.completed, .missed, .completed, .completed, .completed, .completed, .notScheduled],
            [.completed, .completed, .completed, .missed, .completed, .completed, .notScheduled],
            [.completed, .completed, .missed, .completed, .completed, .completed, .notScheduled],
            [.completed, .completed, .completed, .completed, .future, .future, .future],
        ],
        nextMilestone: 21, isEmpty: false
    )
}

// MARK: Single Habit Provider

struct SingleHabitProvider: AppIntentTimelineProvider {
    typealias Intent = SelectHabitIntent
    typealias Entry = SingleHabitEntry

    func placeholder(in context: Context) -> SingleHabitEntry {
        placeholderSingleEntry()
    }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> SingleHabitEntry {
        await buildEntry(for: configuration.habit?.id)
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<SingleHabitEntry> {
        let entry = await buildEntry(for: configuration.habit?.id)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(next))
    }

    @MainActor
    private func buildEntry(for habitID: String?) -> SingleHabitEntry {
        guard let habitID else { return emptySingleEntry() }

        let ctx = WidgetData.container.mainContext
        let descriptor = FetchDescriptor<Habit>()
        guard let allHabits = try? ctx.fetch(descriptor),
              let habit = allHabits.first(where: { $0.id.uuidString == habitID })
        else { return emptySingleEntry() }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Last 7 days
        let last7: [DayStatus] = (0..<7).reversed().map { i in
            let day = today.adding(days: -i)
            if !habit.isScheduledOn(day) { return .notScheduled }
            return habit.isCompletedOn(day) ? .completed : .missed
        }

        // 4-week heatmap aligned to weekday columns
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        let thisMonday = today.adding(days: -daysSinceMonday)

        let heatmap: [[DayStatus]] = (0..<4).map { week in
            let weekStart = thisMonday.adding(days: (week - 3) * 7)
            return (0..<7).map { day in
                let date = weekStart.adding(days: day)
                if date > today { return .future }
                if !habit.isScheduledOn(date) { return .notScheduled }
                return habit.isCompletedOn(date) ? .completed : .missed
            }
        }

        return SingleHabitEntry(
            date: Date(),
            habitName: habit.name, habitEmoji: habit.emoji,
            habitColorHex: habit.colorHex, isCompletedToday: habit.isCompletedToday,
            currentStreak: habit.currentStreak, bestStreak: habit.bestStreak,
            completionRate: habit.completionRate, totalCompletions: habit.totalCompletions,
            last7Days: last7, heatmapWeeks: heatmap,
            nextMilestone: habit.nextMilestone, isEmpty: false
        )
    }
}

// MARK: - Single Habit gradient

private struct HabitGradient: View {
    let hex: String
    var body: some View {
        ZStack {
            Color.black
            LinearGradient(
                stops: [
                    .init(color: Color(hex: hex).opacity(0.95), location: 0),
                    .init(color: Color(hex: hex).opacity(0.65), location: 1),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - "Select a habit" prompt

private struct SelectHabitPrompt: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.5))
            Text("Hold to choose\na habit")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: Habit Small

struct HabitSmallView: View {
    let entry: SingleHabitEntry

    var body: some View {
        if entry.isEmpty {
            VStack { SelectHabitPrompt() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(for: .widget) { HabitGradient(hex: "34C759") }
        } else {
            VStack(spacing: 0) {
                HStack {
                    Text(entry.habitName)
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                    Spacer()
                    if entry.isCompletedToday {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                }

                Spacer()

                Text(entry.habitEmoji)
                    .font(.system(size: 48))
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

                Spacer()

                if entry.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").font(.system(size: 11)).foregroundStyle(.orange)
                        Text("\(entry.currentStreak) days")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 6)
                }

                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { i in
                        let status = i < entry.last7Days.count ? entry.last7Days[i] : .notScheduled
                        Circle()
                            .fill(dotColor(status))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .containerBackground(for: .widget) { HabitGradient(hex: entry.habitColorHex) }
        }
    }
}

// MARK: Habit Medium

struct HabitMediumView: View {
    let entry: SingleHabitEntry

    private var weekLabels: [String] {
        let today = Date().startOfDay
        return (0..<7).reversed().map { i in
            String(today.adding(days: -i).formatted(.dateTime.weekday(.narrow)))
        }
    }

    var body: some View {
        if entry.isEmpty {
            HStack { Spacer(); SelectHabitPrompt(); Spacer() }
                .containerBackground(for: .widget) { HabitGradient(hex: "34C759") }
        } else {
            HStack(spacing: 14) {
                // Left: emoji circle + streak
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Text(entry.habitEmoji)
                            .font(.system(size: 32))
                        if entry.isCompletedToday {
                            Circle().stroke(.white, lineWidth: 2.5)
                                .frame(width: 64, height: 64)
                        }
                    }

                    if entry.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill").font(.system(size: 9))
                            Text("\(entry.currentStreak)d")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                }

                // Right: name + stats + 7-day strip
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.habitName)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.bottom, 2)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Best").font(.system(size: 8, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("\(entry.bestStreak)d").font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Rate").font(.system(size: 8, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("\(Int(entry.completionRate * 100))%").font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.bottom, 8)

                    Spacer(minLength: 0)

                    HStack(spacing: 5) {
                        ForEach(0..<7, id: \.self) { i in
                            let status = i < entry.last7Days.count ? entry.last7Days[i] : .notScheduled
                            VStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(dotColor(status))
                                    .frame(width: 14, height: 14)
                                Text(weekLabels[i])
                                    .font(.system(size: 7, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                    }
                }
            }
            .containerBackground(for: .widget) { HabitGradient(hex: entry.habitColorHex) }
        }
    }
}

// MARK: Habit Large

struct HabitLargeView: View {
    let entry: SingleHabitEntry
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        if entry.isEmpty {
            VStack { Spacer(); SelectHabitPrompt(); Spacer() }
                .frame(maxWidth: .infinity)
                .containerBackground(for: .widget) { HabitGradient(hex: "34C759") }
        } else {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(entry.habitEmoji).font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.habitName)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.white).lineLimit(1)
                        if entry.isCompletedToday {
                            Text("Done today")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    Spacer()
                    if entry.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill").font(.system(size: 12))
                            Text("\(entry.currentStreak)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(.bottom, 14)

                // 4-week heatmap
                VStack(spacing: 4) {
                    // Day labels
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { d in
                            Text(dayLabels[d])
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                        }
                    }

                    ForEach(0..<4, id: \.self) { week in
                        HStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { day in
                                let status = (week < entry.heatmapWeeks.count && day < entry.heatmapWeeks[week].count)
                                    ? entry.heatmapWeeks[week][day] : .future
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(heatmapColor(status))
                                    .aspectRatio(1, contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .padding(.bottom, 14)

                // Stats row
                HStack(spacing: 0) {
                    statCard(value: "\(entry.currentStreak)", label: "Current")
                    statCard(value: "\(entry.bestStreak)", label: "Best")
                    statCard(value: "\(Int(entry.completionRate * 100))%", label: "Rate")
                    statCard(value: "\(entry.totalCompletions)", label: "Total")
                }
                .padding(.bottom, 12)

                Spacer(minLength: 0)

                // Milestone progress
                if let next = entry.nextMilestone {
                    VStack(spacing: 5) {
                        HStack {
                            Text("Next: \(next) days")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                            Text("\(entry.currentStreak)/\(next)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.12))
                                Capsule().fill(.white.opacity(0.8))
                                    .frame(width: max(0, geo.size.width * Double(entry.currentStreak) / Double(next)))
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
            .containerBackground(for: .widget) { HabitGradient(hex: entry.habitColorHex) }
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 2)
    }
}

// MARK: Single Habit Widget Config

struct SingleHabitWidget: Widget {
    let kind = "singleHabitWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectHabitIntent.self, provider: SingleHabitProvider()) { entry in
            SingleHabitEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Focus")
        .description("Dive deep into a single habit's progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct SingleHabitEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SingleHabitEntry
    var body: some View {
        switch family {
        case .systemMedium: HabitMediumView(entry: entry)
        case .systemLarge:  HabitLargeView(entry: entry)
        default:            HabitSmallView(entry: entry)
        }
    }
}

// MARK: - Shared color helpers

private func dotColor(_ status: DayStatus) -> Color {
    switch status {
    case .completed:    return .white
    case .missed:       return .white.opacity(0.15)
    case .notScheduled: return .white.opacity(0.06)
    case .future:       return .clear
    }
}

private func heatmapColor(_ status: DayStatus) -> Color {
    switch status {
    case .completed:    return .white.opacity(0.85)
    case .missed:       return .white.opacity(0.1)
    case .notScheduled: return .white.opacity(0.04)
    case .future:       return .clear
    }
}
