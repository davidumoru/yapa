import SwiftUI

struct HeatmapCalendarView: View {
    let habit: Habit
    var weeks: Int = 16

    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 3
    private var accentColor: Color { Color(hex: habit.colorHex) }

    private var grid: [[Date]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todayWeekday = calendar.component(.weekday, from: today)
        let daysToSaturday = 7 - todayWeekday
        let endOfWeek = today.adding(days: daysToSaturday)
        let totalDays = weeks * 7
        let startDate = endOfWeek.adding(days: -(totalDays - 1))

        var columns: [[Date]] = []
        var currentWeek: [Date] = []

        for i in 0..<totalDays {
            let date = startDate.adding(days: i)
            currentWeek.append(date)
            if currentWeek.count == 7 {
                columns.append(currentWeek)
                currentWeek = []
            }
        }
        if !currentWeek.isEmpty {
            columns.append(currentWeek)
        }

        return columns
    }

    private var completedDays: Set<Date> {
        Set(habit.entries.map { Calendar.current.startOfDay(for: $0.date) })
    }

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: cellSpacing) {
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { row in
                                if row % 2 == 1 {
                                    Text(dayLabels[row])
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .frame(width: cellSize, height: cellSize)
                                } else {
                                    Color.clear
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }

                        ForEach(Array(grid.enumerated()), id: \.offset) { weekIdx, week in
                            VStack(spacing: cellSpacing) {
                                ForEach(Array(week.enumerated()), id: \.offset) { dayIdx, date in
                                    let today = Calendar.current.startOfDay(for: Date())
                                    let isFuture = date > today
                                    let isBeforeCreation = date < Calendar.current.startOfDay(for: habit.createdAt)
                                    let isCompleted = completedDays.contains(date)

                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(cellColor(
                                            isCompleted: isCompleted,
                                            isFuture: isFuture,
                                            isBeforeCreation: isBeforeCreation
                                        ))
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                            .id(weekIdx)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .onAppear {
                    proxy.scrollTo(grid.count - 1, anchor: .trailing)
                }
            }

            HStack(spacing: 4) {
                Text("Less")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.secondary)

                ForEach(0..<4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(level == 0 ? Color(.systemGray5) : accentColor.opacity(Double(level) / 3.0))
                        .frame(width: 10, height: 10)
                }

                Text("More")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func cellColor(isCompleted: Bool, isFuture: Bool, isBeforeCreation: Bool) -> Color {
        if isFuture || isBeforeCreation {
            return Color(.systemGray6).opacity(0.5)
        }
        return isCompleted ? accentColor : Color(.systemGray5)
    }
}
