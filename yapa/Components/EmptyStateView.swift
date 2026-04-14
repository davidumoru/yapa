import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Text(title)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
