import SwiftUI

struct MilestonesView: View {
    let habit: Habit

    private var allMilestones: [(days: Int, name: String, icon: String, colorHex: String)] {
        Habit.milestoneThresholds
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Milestones")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if let next = habit.nextMilestone {
                    let remaining = next.days - habit.bestStreak
                    Text("\(remaining) days to \(next.name)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(allMilestones, id: \.days) { milestone in
                    let achieved = habit.bestStreak >= milestone.days
                    milestoneBadge(milestone: milestone, achieved: achieved)
                }
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func milestoneBadge(
        milestone: (days: Int, name: String, icon: String, colorHex: String),
        achieved: Bool
    ) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        achieved
                            ? Color(hex: milestone.colorHex).opacity(0.15)
                            : Color(.systemGray6)
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: milestone.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        achieved
                            ? Color(hex: milestone.colorHex)
                            : Color(.systemGray4)
                    )
            }

            Text("\(milestone.days)d")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(achieved ? .primary : .secondary)

            Text(milestone.name)
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}
