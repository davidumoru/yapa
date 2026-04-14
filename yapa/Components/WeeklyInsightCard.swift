import SwiftUI

struct WeeklyInsightCard: View {
    let habits: [Habit]

    private var thisWeekRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = today.adding(days: -(weekday - calendar.firstWeekday + 7) % 7)
        return startOfWeek...today
    }

    private var lastWeekRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let startOfThisWeek = today.adding(days: -(weekday - calendar.firstWeekday + 7) % 7)
        let endOfLastWeek = startOfThisWeek.adding(days: -1)
        let startOfLastWeek = startOfThisWeek.adding(days: -7)
        return startOfLastWeek...endOfLastWeek
    }

    private var thisWeekRate: Double {
        var totalDone = 0
        var totalScheduled = 0
        for habit in habits {
            let stats = habit.completionCount(in: thisWeekRange)
            totalDone += stats.completed
            totalScheduled += stats.scheduled
        }
        guard totalScheduled > 0 else { return 0 }
        return Double(totalDone) / Double(totalScheduled)
    }

    private var lastWeekRate: Double {
        var totalDone = 0
        var totalScheduled = 0
        for habit in habits {
            let stats = habit.completionCount(in: lastWeekRange)
            totalDone += stats.completed
            totalScheduled += stats.scheduled
        }
        guard totalScheduled > 0 else { return 0 }
        return Double(totalDone) / Double(totalScheduled)
    }

    private var trend: Trend {
        let diff = thisWeekRate - lastWeekRate
        if diff > 0.05 { return .up }
        if diff < -0.05 { return .down }
        return .steady
    }

    private enum Trend {
        case up, down, steady

        var icon: String {
            switch self {
            case .up: "arrow.up.right"
            case .down: "arrow.down.right"
            case .steady: "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: .green
            case .down: .orange
            case .steady: .blue
            }
        }

        var label: String {
            switch self {
            case .up: "Improving"
            case .down: "Needs focus"
            case .steady: "Holding steady"
            }
        }
    }

    private var dayBars: [(label: String, thisWeek: Double, lastWeek: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let startOfThisWeek = today.adding(days: -(weekday - calendar.firstWeekday + 7) % 7)
        let startOfLastWeek = startOfThisWeek.adding(days: -7)

        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
        var bars: [(String, Double, Double)] = []

        for i in 0..<7 {
            let thisDay = startOfThisWeek.adding(days: i)
            let lastDay = startOfLastWeek.adding(days: i)
            let isFuture = thisDay > today

            var thisDayRate: Double = 0
            var lastDayRate: Double = 0
            var thisDayTotal = 0
            var thisDayDone = 0
            var lastDayTotal = 0
            var lastDayDone = 0

            for habit in habits {
                if habit.isScheduledOn(thisDay) {
                    thisDayTotal += 1
                    if habit.isCompletedOn(thisDay) { thisDayDone += 1 }
                }
                if habit.isScheduledOn(lastDay) {
                    lastDayTotal += 1
                    if habit.isCompletedOn(lastDay) { lastDayDone += 1 }
                }
            }

            if !isFuture && thisDayTotal > 0 {
                thisDayRate = Double(thisDayDone) / Double(thisDayTotal)
            }
            if lastDayTotal > 0 {
                lastDayRate = Double(lastDayDone) / Double(lastDayTotal)
            }

            let dayIndex = (calendar.firstWeekday - 1 + i) % 7
            bars.append((dayLabels[dayIndex], isFuture ? -1 : thisDayRate, lastDayRate))
        }

        return bars
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Progress")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 12, weight: .bold))
                    Text(trend.label)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(trend.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(trend.color.opacity(0.12))
                .clipShape(Capsule())
            }

            HStack(spacing: 0) {
                weekStat(
                    label: "This week",
                    rate: thisWeekRate,
                    color: Color.accentColor
                )

                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 1, height: 36)
                    .padding(.horizontal, 16)

                weekStat(
                    label: "Last week",
                    rate: lastWeekRate,
                    color: .secondary
                )

                Spacer()
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(dayBars.enumerated()), id: \.offset) { _, bar in
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color(.systemGray5))
                                .frame(width: 14, height: 40)

                            if bar.thisWeek >= 0 {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.accentColor)
                                    .frame(width: 14, height: max(2, CGFloat(bar.thisWeek) * 40))
                            }

                            RoundedRectangle(cornerRadius: 1, style: .continuous)
                                .fill(Color(.systemGray3))
                                .frame(width: 14, height: 2)
                                .offset(y: -CGFloat(bar.lastWeek) * 40 + 1)
                        }

                        Text(bar.label)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.accentColor)
                        .frame(width: 10, height: 10)
                    Text("This week")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(Color(.systemGray3))
                        .frame(width: 10, height: 2)
                    Text("Last week")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func weekStat(label: String, rate: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(Int(rate * 100))%")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
