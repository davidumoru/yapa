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

    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry] = []

    init(
        name: String,
        emoji: String,
        colorHex: String = "34C759",
        scheduledWeekdays: [Int] = [],
        targetDays: Int = 0,
        reminderMinutes: [Int] = []
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.scheduledWeekdays = scheduledWeekdays
        self.targetDays = targetDays
        self.reminderMinutes = reminderMinutes
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

    // MARK: - Streak calculation

    var currentStreak: Int {
        let calendar = Calendar.current
        let completedDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        guard !completedDays.isEmpty else { return 0 }

        var checkDate = calendar.startOfDay(for: Date())

        // Allow streak to continue if today isn't done yet — check from yesterday
        if !completedDays.contains(checkDate) {
            checkDate = checkDate.adding(days: -1)
        }

        var streak = 0
        let earliest = calendar.startOfDay(for: createdAt)

        while checkDate >= earliest {
            if isScheduledOn(checkDate) {
                if completedDays.contains(checkDate) {
                    streak += 1
                } else {
                    break
                }
            }
            checkDate = checkDate.adding(days: -1)
        }

        return streak
    }

    var bestStreak: Int {
        let calendar = Calendar.current
        let completedDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        guard !completedDays.isEmpty else { return 0 }

        let earliest = calendar.startOfDay(for: createdAt)
        var checkDate = earliest
        let today = calendar.startOfDay(for: Date())
        var current = 0
        var best = 0

        while checkDate <= today {
            if isScheduledOn(checkDate) {
                if completedDays.contains(checkDate) {
                    current += 1
                    best = max(best, current)
                } else {
                    current = 0
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
}
