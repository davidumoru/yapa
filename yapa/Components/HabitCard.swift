import SwiftUI
import SwiftData

struct HabitCard: View {
    let habit: Habit
    let onToggle: () -> Void

    @State private var animateCheck = false

    private var accentColor: Color { Color(hex: habit.colorHex) }

    var body: some View {
        HStack(spacing: 16) {
            Text(habit.emoji)
                .font(.system(size: 32))
                .frame(width: 48, height: 48)
                .background(accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    if habit.currentStreak > 0 {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(habit.currentStreak) day streak")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Start your streak today")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    animateCheck = true
                    onToggle()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    animateCheck = false
                }
            }) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            habit.isCompletedToday ? accentColor : Color(.systemGray4),
                            lineWidth: 2.5
                        )
                        .frame(width: 32, height: 32)

                    if habit.isCompletedToday {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 32, height: 32)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(animateCheck ? 1.3 : 1.0)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}
