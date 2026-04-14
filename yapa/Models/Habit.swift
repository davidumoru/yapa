import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "🎯"
    var colorHex: String = "34C759"
    /// Empty means every day; otherwise weekday ints 1(Sun)–7(Sat)
    var scheduledWeekdays: [Int] = []
    /// 0 means track forever
    var targetDays: Int = 0
    /// Each value is minutes from midnight (e.g. 480 = 8:00 AM)
    var reminderMinutes: [Int] = []
    var createdAt: Date = Date()
    var isArchived: Bool = false
    var sortOrder: Int = 0
    /// How many consecutive scheduled days can be missed without breaking a streak (0-2)
    var graceDays: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry] = []

    init(
        name: String,
        emoji: String,
        colorHex: String = "34C759",
        scheduledWeekdays: [Int] = [],
        targetDays: Int = 0,
        reminderMinutes: [Int] = [],
        graceDays: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.scheduledWeekdays = scheduledWeekdays
        self.targetDays = targetDays
        self.reminderMinutes = reminderMinutes
        self.graceDays = graceDays
        self.createdAt = Date()
        self.isArchived = false
        self.entries = []
    }

    // MARK: - Schedule helpers

    func isScheduledOn(_ date: Date) -> Bool {
        if scheduledWeekdays.isEmpty { return true }
        return scheduledWeekdays.contains(date.weekday)
    }

    var isScheduledToday: Bool { isScheduledOn(Date()) }

    // MARK: - Completion helpers

    func isCompletedOn(_ date: Date) -> Bool {
        let target = date.startOfDay
        return entries.contains { $0.date.startOfDay == target }
    }

    var isCompletedToday: Bool { isCompletedOn(Date()) }

    private var completedDaySet: Set<Date> {
        Set(entries.map { Calendar.current.startOfDay(for: $0.date) })
    }

    // MARK: - Streak calculation (grace-day aware)

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
                    if consecutiveMisses > graceDays {
                        break
                    }
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
        let earliest = calendar.startOfDay(for: createdAt)
        var checkDate = earliest
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

    var totalScheduledDays: Int {
        let calendar = Calendar.current
        let earliest = calendar.startOfDay(for: createdAt)
        let today = calendar.startOfDay(for: Date())
        var count = 0
        var date = earliest
        while date <= today {
            if isScheduledOn(date) { count += 1 }
            date = date.adding(days: 1)
        }
        return max(count, 1)
    }

    var completionRate: Double {
        Double(entries.count) / Double(totalScheduledDays)
    }

    var endDate: Date? {
        guard targetDays > 0 else { return nil }
        return createdAt.adding(days: targetDays)
    }

    var daysRemaining: Int? {
        guard let end = endDate else { return nil }
        let remaining = Date().daysBetween(end)
        return max(remaining, 0)
    }

    // MARK: - Weekly stats

    func completionCount(in range: ClosedRange<Date>) -> (completed: Int, scheduled: Int) {
        let calendar = Calendar.current
        let completed = completedDaySet
        var date = calendar.startOfDay(for: range.lowerBound)
        let end = calendar.startOfDay(for: range.upperBound)
        var done = 0
        var total = 0

        while date <= end {
            if isScheduledOn(date) {
                total += 1
                if completed.contains(date) { done += 1 }
            }
            date = date.adding(days: 1)
        }
        return (done, total)
    }

    // MARK: - Milestones

    static let milestoneThresholds: [(days: Int, name: String, icon: String, colorHex: String)] = [
        (7, "First Week", "star.fill", "FFD60A"),
        (21, "Habit Formed", "brain", "AF52DE"),
        (30, "One Month", "moon.fill", "007AFF"),
        (60, "Two Months", "flame.fill", "FF9500"),
        (90, "Quarter Year", "trophy.fill", "FFD60A"),
        (180, "Half Year", "crown.fill", "5856D6"),
        (365, "One Year", "sparkles", "FF2D55"),
    ]

    var achievedMilestones: [(days: Int, name: String, icon: String, colorHex: String)] {
        let best = bestStreak
        return Self.milestoneThresholds.filter { best >= $0.days }
    }

    var nextMilestone: (days: Int, name: String, icon: String, colorHex: String)? {
        let best = bestStreak
        return Self.milestoneThresholds.first { best < $0.days }
    }
}
