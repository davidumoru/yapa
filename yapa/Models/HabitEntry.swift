import Foundation
import SwiftData

@Model
final class HabitEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var completedAt: Date = Date()
    var note: String = ""
    var habit: Habit?

    init(date: Date, habit: Habit) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = Date()
        self.habit = habit
    }
}
