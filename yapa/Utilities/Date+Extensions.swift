import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    func daysBetween(_ other: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self)
        let end = calendar.startOfDay(for: other)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    var dayOfMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    var weekdayInitial: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: self)
    }
}
