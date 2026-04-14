//
//  ContentView.swift
//  yapa
//
//  Created by David Umoru on 13/04/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab = 0
    private var settings = AppSettings.shared

    var body: some View {
        if hasSeenOnboarding {
            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem {
                        Label("Today", systemImage: "sun.max.fill")
                    }
                    .tag(0)

                HabitsListView()
                    .tabItem {
                        Label("Habits", systemImage: "square.grid.2x2.fill")
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(2)
            }
            .tint(Color(hex: "34C759"))
            .preferredColorScheme(settings.theme.colorScheme)
        } else {
            OnboardingView()
                .preferredColorScheme(settings.theme.colorScheme)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}
