import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    @State private var showCreateHabit = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sun.max.fill",
            iconColor: Color(hex: "FFD60A"),
            title: "Welcome to yapa",
            subtitle: "Yet another productivity app.\nBut this one's yours.",
            accent: Color(hex: "34C759")
        ),
        OnboardingPage(
            icon: "checkmark.circle.fill",
            iconColor: Color(hex: "34C759"),
            title: "Build habits\nthat stick",
            subtitle: "Track daily or weekly. Set reminders.\nStay flexible — life happens.",
            accent: Color(hex: "34C759")
        ),
        OnboardingPage(
            icon: "flame.fill",
            iconColor: .orange,
            title: "Watch yourself\ngrow",
            subtitle: "Streaks, milestones, weekly insights.\nSmall wins compound into big changes.",
            accent: .orange
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            bottomSection
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showCreateHabit, onDismiss: { finish() }) {
            CreateHabitView()
        }
    }

    // MARK: - Page Content

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(page.iconColor.opacity(0.06))
                    .frame(width: 200, height: 200)
                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(page.iconColor)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.bottom, 48)

            Text(page.title)
                .font(.system(.title, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            Text(page.subtitle)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 36)
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 20) {
            // Page dots
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color(hex: "34C759") : Color(.systemGray4))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.35), value: currentPage)
                }
            }

            if currentPage < pages.count - 1 {
                // Next button
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("Continue")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(hex: "34C759"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button("Skip") {
                    finish()
                }
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
            } else {
                // Final page: two options
                Button {
                    requestNotificationsAndCreateHabit()
                } label: {
                    Text("Create your first habit")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(hex: "34C759"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button("I'll explore first") {
                    requestNotificationsAndFinish()
                }
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func requestNotificationsAndCreateHabit() {
        Task {
            await NotificationManager.shared.requestAuthorization()
            showCreateHabit = true
        }
    }

    private func requestNotificationsAndFinish() {
        Task {
            await NotificationManager.shared.requestAuthorization()
            finish()
        }
    }

    private func finish() {
        withAnimation(.easeInOut(duration: 0.35)) {
            hasSeenOnboarding = true
        }
    }
}

// MARK: - Page Model

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let accent: Color
}
