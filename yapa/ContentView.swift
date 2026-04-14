//
//  ContentView.swift
//  yapa
//
//  Created by David Umoru on 13/04/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
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
        }
        .tint(Color(hex: "34C759"))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}
