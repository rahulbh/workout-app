//
//  workout_appApp.swift
//  workout-app
//
//  Created by Rahul Bharti on 28/11/25.
//

import SwiftUI
import SwiftData

@main
struct workout_appApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            WorkoutLog.self,
            SetLog.self,
            Routine.self,
            UserPreferences.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
