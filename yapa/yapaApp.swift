//
//  yapaApp.swift
//  yapa
//
//  Created by David Umoru on 13/04/2026.
//

import SwiftUI
import SwiftData

@main
struct yapaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Habit.self, HabitEntry.self])
    }
}
