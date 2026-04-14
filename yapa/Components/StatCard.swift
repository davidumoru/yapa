import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
