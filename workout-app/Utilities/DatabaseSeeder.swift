//
//  DatabaseSeeder.swift
//  workout-app
//
//  Created by Claude Code
//

import Foundation
import SwiftData

struct DatabaseSeeder {
    /// Seeds the database with pre-loaded exercises if no exercises exist
    static func seedExercisesIfNeeded(context: ModelContext) {
        // Check if exercises already exist
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        // Only seed if database is empty
//        guard (existingCount == 0 || existingCount == 1) else {
//            print("Database already contains \(existingCount) exercises. Skipping seed.")
//            return
//        }

        print("Seeding database with pre-loaded exercises...")

        // Load exercises from JSON file
        guard let exercises = loadExercisesFromJSON() else {
            print("Failed to load exercises from JSON file")
            return
        }

        // Insert exercises into database
        var insertedCount = 0
        for exerciseData in exercises {
            let exercise = Exercise(
                name: exerciseData.name,
                targetMuscleGroup: exerciseData.targetMuscleGroup,
                instructions: exerciseData.instructions,
                formCues: exerciseData.formCues,
                videoURL: exerciseData.videoURL
            )
            context.insert(exercise)
            insertedCount += 1
        }

        // Save context
        do {
            try context.save()
            print("Successfully seeded \(insertedCount) exercises")
        } catch {
            print("Error saving seeded exercises: \(error)")
        }
    }

    /// Loads exercise data from the bundled JSON file
    private static func loadExercisesFromJSON() -> [ExerciseData]? {
        guard let url = Bundle.main.url(forResource: "PreloadedExercises", withExtension: "json") else {
            print("⚠️ PreloadedExercises.json not found in bundle.")
            print("Add the file to Xcode: Data/PreloadedExercises.json")
            print("Skipping pre-loaded exercises for now.")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let exercises = try decoder.decode([ExerciseData].self, from: data)
            return exercises
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
}

/// Codable struct for decoding exercise data from JSON
struct ExerciseData: Codable {
    let name: String
    let targetMuscleGroup: String
    let instructions: String?
    let formCues: String?
    let videoURL: String?
}
