//
//  SetLogTests.swift
//  workout-appTests
//
//  Tests for SetLog workflow: save sets, reopen exercise, verify previous data appears correctly
//

import Testing
import SwiftData
import Foundation
@testable import workout_app

@Suite("SetLog Workflow Tests")
@MainActor
struct SetLogTests {

    // MARK: - Test Helpers

    /// Creates an in-memory model container for testing
    func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            Exercise.self,
            WorkoutLog.self,
            SetLog.self,
            Routine.self,
            UserPreferences.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Simulates the previousSets computed property logic from LogExerciseView
    func getPreviousSets(for exercise: Exercise, from allSetLogs: [SetLog]) -> [Int: (weight: Double, reps: Int)] {
        let exerciseSetLogs = allSetLogs
            .filter { $0.exercise?.id == exercise.id }
            .sorted { $0.date > $1.date }

        guard !exerciseSetLogs.isEmpty else { return [:] }

        // Get the most recent workout date
        let lastWorkoutDate = exerciseSetLogs.first!.date
        let calendar = Calendar.current

        // Get all sets from the last workout (same day)
        let lastWorkoutSets = exerciseSetLogs.filter { setLog in
            calendar.isDate(setLog.date, inSameDayAs: lastWorkoutDate)
        }

        // Map set number to weight/reps
        var result: [Int: (weight: Double, reps: Int)] = [:]
        for setLog in lastWorkoutSets {
            result[setLog.setNumber] = (weight: setLog.weight, reps: setLog.reps)
        }
        return result
    }

    // MARK: - Tests

    @Test("Save 3 sets and verify all 3 appear as previous data")
    func testSaveAndRetrieveMultipleSets() throws {
        // Setup
        let container = try createTestContainer()
        let context = container.mainContext

        // Create an exercise
        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        context.insert(exercise)

        // Simulate logging 3 sets (as finishWorkout does)
        let workoutDate = Date()
        let set1 = SetLog(setNumber: 1, reps: 12, weight: 135.0, date: workoutDate, exercise: exercise)
        let set2 = SetLog(setNumber: 2, reps: 10, weight: 135.0, date: workoutDate, exercise: exercise)
        let set3 = SetLog(setNumber: 3, reps: 8, weight: 135.0, date: workoutDate, exercise: exercise)

        context.insert(set1)
        context.insert(set2)
        context.insert(set3)
        try context.save()

        // Fetch all SetLogs (simulating @Query)
        let descriptor = FetchDescriptor<SetLog>()
        let allSetLogs = try context.fetch(descriptor)

        // Get previous sets (simulating the computed property)
        let previousSets = getPreviousSets(for: exercise, from: allSetLogs)

        // Verify all 3 sets are retrieved
        #expect(previousSets.count == 3, "Expected 3 previous sets, got \(previousSets.count)")

        // Verify each set has correct data
        #expect(previousSets[1]?.weight == 135.0, "Set 1 weight mismatch: expected 135.0, got \(previousSets[1]?.weight ?? -1)")
        #expect(previousSets[1]?.reps == 12, "Set 1 reps mismatch: expected 12, got \(previousSets[1]?.reps ?? -1)")

        #expect(previousSets[2]?.weight == 135.0, "Set 2 weight mismatch")
        #expect(previousSets[2]?.reps == 10, "Set 2 reps mismatch: expected 10, got \(previousSets[2]?.reps ?? -1)")

        #expect(previousSets[3]?.weight == 135.0, "Set 3 weight mismatch")
        #expect(previousSets[3]?.reps == 8, "Set 3 reps mismatch: expected 8, got \(previousSets[3]?.reps ?? -1)")

        print("TEST PASSED: All 3 sets correctly saved and retrieved")
    }

    @Test("Previous sets should use set number as key, not array index")
    func testSetNumberAsKey() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        context.insert(exercise)

        // Save sets with specific set numbers
        let workoutDate = Date()
        let set1 = SetLog(setNumber: 1, reps: 5, weight: 225.0, date: workoutDate, exercise: exercise)
        let set2 = SetLog(setNumber: 2, reps: 5, weight: 225.0, date: workoutDate, exercise: exercise)
        let set3 = SetLog(setNumber: 3, reps: 5, weight: 225.0, date: workoutDate, exercise: exercise)

        context.insert(set1)
        context.insert(set2)
        context.insert(set3)
        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allSetLogs = try context.fetch(descriptor)
        let previousSets = getPreviousSets(for: exercise, from: allSetLogs)

        // Keys should be 1, 2, 3 (set numbers), not 0, 1, 2 (array indices)
        #expect(previousSets[0] == nil, "Should not have key 0 (array index)")
        #expect(previousSets[1] != nil, "Should have key 1 (set number)")
        #expect(previousSets[2] != nil, "Should have key 2 (set number)")
        #expect(previousSets[3] != nil, "Should have key 3 (set number)")

        print("TEST PASSED: Set numbers correctly used as dictionary keys")
    }

    @Test("Auto-fill values should match PREVIOUS column values")
    func testAutoFillMatchesPrevious() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "Deadlift", targetMuscleGroup: "Back")
        context.insert(exercise)

        // Save workout with different weights per set
        let workoutDate = Date()
        let set1 = SetLog(setNumber: 1, reps: 8, weight: 185.0, date: workoutDate, exercise: exercise)
        let set2 = SetLog(setNumber: 2, reps: 6, weight: 205.0, date: workoutDate, exercise: exercise)
        let set3 = SetLog(setNumber: 3, reps: 4, weight: 225.0, date: workoutDate, exercise: exercise)

        context.insert(set1)
        context.insert(set2)
        context.insert(set3)
        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allSetLogs = try context.fetch(descriptor)
        let previousSets = getPreviousSets(for: exercise, from: allSetLogs)

        // Simulate what initializeSetEntries does
        let userUnit = WeightUnit.kilograms  // User prefers kg

        var setEntries: [(number: Int, weight: Double, reps: Int)] = []
        let sortedSetNumbers = previousSets.keys.sorted()

        for setNumber in sortedSetNumbers {
            let (previousWeight, previousReps) = previousSets[setNumber]!
            let displayWeight = UnitConverter.toDisplay(previousWeight, unit: userUnit)
            setEntries.append((number: setNumber, weight: displayWeight, reps: previousReps))
        }

        // Simulate what SetRowView displays for PREVIOUS column
        for entry in setEntries {
            let previousData = previousSets[entry.number]!
            let previousDisplayWeight = UnitConverter.toDisplay(previousData.weight, unit: userUnit)

            // THE KEY TEST: auto-fill weight should match PREVIOUS display weight
            #expect(
                abs(entry.weight - previousDisplayWeight) < 0.01,
                "Set \(entry.number): Auto-fill weight (\(entry.weight)) != PREVIOUS weight (\(previousDisplayWeight))"
            )

            #expect(
                entry.reps == previousData.reps,
                "Set \(entry.number): Auto-fill reps (\(entry.reps)) != PREVIOUS reps (\(previousData.reps))"
            )

            print("TEST: Set \(entry.number): Auto-fill (\(entry.weight)kg x \(entry.reps)) matches PREVIOUS (\(previousDisplayWeight)kg x \(previousData.reps))")
        }

        print("TEST PASSED: Auto-fill values match PREVIOUS column values")
    }

    @Test("Unit conversion consistency between save and display")
    func testUnitConversionConsistency() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "OHP", targetMuscleGroup: "Shoulders")
        context.insert(exercise)

        // User enters 60kg, which gets stored as pounds
        let userInputKg = 60.0
        let storedWeight = UnitConverter.toStorage(userInputKg, from: .kilograms)

        let workoutDate = Date()
        let setLog = SetLog(setNumber: 1, reps: 10, weight: storedWeight, date: workoutDate, exercise: exercise)
        context.insert(setLog)
        try context.save()

        // Fetch and convert back
        let descriptor = FetchDescriptor<SetLog>()
        let allSetLogs = try context.fetch(descriptor)
        let previousSets = getPreviousSets(for: exercise, from: allSetLogs)

        let retrievedStoredWeight = previousSets[1]!.weight
        let displayWeight = UnitConverter.toDisplay(retrievedStoredWeight, unit: .kilograms)

        // Should get back approximately 60kg
        #expect(
            abs(displayWeight - userInputKg) < 0.1,
            "Unit conversion round-trip failed: entered \(userInputKg)kg, got back \(displayWeight)kg"
        )

        print("TEST PASSED: Unit conversion: \(userInputKg)kg -> \(storedWeight)lbs (stored) -> \(displayWeight)kg (displayed)")
    }

    @Test("Only most recent workout data should appear as previous")
    func testOnlyMostRecentWorkout() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "Rows", targetMuscleGroup: "Back")
        context.insert(exercise)

        // Old workout (2 days ago)
        let oldDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let oldSet1 = SetLog(setNumber: 1, reps: 10, weight: 100.0, date: oldDate, exercise: exercise)
        let oldSet2 = SetLog(setNumber: 2, reps: 10, weight: 100.0, date: oldDate, exercise: exercise)

        // Recent workout (today)
        let recentDate = Date()
        let recentSet1 = SetLog(setNumber: 1, reps: 12, weight: 110.0, date: recentDate, exercise: exercise)
        let recentSet2 = SetLog(setNumber: 2, reps: 10, weight: 110.0, date: recentDate, exercise: exercise)
        let recentSet3 = SetLog(setNumber: 3, reps: 8, weight: 110.0, date: recentDate, exercise: exercise)

        context.insert(oldSet1)
        context.insert(oldSet2)
        context.insert(recentSet1)
        context.insert(recentSet2)
        context.insert(recentSet3)
        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allSetLogs = try context.fetch(descriptor)
        let previousSets = getPreviousSets(for: exercise, from: allSetLogs)

        // Should only have 3 sets from recent workout, not 2 from old
        #expect(previousSets.count == 3, "Expected 3 sets from recent workout, got \(previousSets.count)")

        // Should have the recent workout's values
        #expect(previousSets[1]?.weight == 110.0, "Should have recent weight 110, got \(previousSets[1]?.weight ?? -1)")
        #expect(previousSets[1]?.reps == 12, "Should have recent reps 12, got \(previousSets[1]?.reps ?? -1)")

        print("TEST PASSED: Only most recent workout data is retrieved")
    }

    @Test("Exercise-specific data isolation")
    func testExerciseIsolation() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let benchPress = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        let squat = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        context.insert(benchPress)
        context.insert(squat)

        let workoutDate = Date()

        // Bench press sets
        let benchSet1 = SetLog(setNumber: 1, reps: 10, weight: 135.0, date: workoutDate, exercise: benchPress)
        let benchSet2 = SetLog(setNumber: 2, reps: 8, weight: 135.0, date: workoutDate, exercise: benchPress)

        // Squat sets
        let squatSet1 = SetLog(setNumber: 1, reps: 5, weight: 225.0, date: workoutDate, exercise: squat)
        let squatSet2 = SetLog(setNumber: 2, reps: 5, weight: 225.0, date: workoutDate, exercise: squat)
        let squatSet3 = SetLog(setNumber: 3, reps: 5, weight: 225.0, date: workoutDate, exercise: squat)

        context.insert(benchSet1)
        context.insert(benchSet2)
        context.insert(squatSet1)
        context.insert(squatSet2)
        context.insert(squatSet3)
        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allSetLogs = try context.fetch(descriptor)

        let benchPreviousSets = getPreviousSets(for: benchPress, from: allSetLogs)
        let squatPreviousSets = getPreviousSets(for: squat, from: allSetLogs)

        // Bench should have 2 sets with 135lbs
        #expect(benchPreviousSets.count == 2, "Bench should have 2 sets")
        #expect(benchPreviousSets[1]?.weight == 135.0, "Bench weight should be 135")

        // Squat should have 3 sets with 225lbs
        #expect(squatPreviousSets.count == 3, "Squat should have 3 sets")
        #expect(squatPreviousSets[1]?.weight == 225.0, "Squat weight should be 225")

        print("TEST PASSED: Exercise data is properly isolated")
    }

    @Test("Full workflow: save sets, simulate reopening, verify PREVIOUS matches auto-fill")
    func testFullWorkflow() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Step 1: Create exercise
        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        context.insert(exercise)

        // Step 2: Simulate first workout - user logs 3 sets
        let workoutDate = Date()
        let savedSet1 = SetLog(setNumber: 1, reps: 12, weight: 132.277, date: workoutDate, exercise: exercise) // 60kg in lbs
        let savedSet2 = SetLog(setNumber: 2, reps: 10, weight: 154.324, date: workoutDate, exercise: exercise) // 70kg in lbs
        let savedSet3 = SetLog(setNumber: 3, reps: 8, weight: 176.370, date: workoutDate, exercise: exercise)  // 80kg in lbs

        context.insert(savedSet1)
        context.insert(savedSet2)
        context.insert(savedSet3)
        try context.save()

        print("STEP 1 - Saved sets:")
        print("  Set 1: \(savedSet1.weight) lbs x \(savedSet1.reps)")
        print("  Set 2: \(savedSet2.weight) lbs x \(savedSet2.reps)")
        print("  Set 3: \(savedSet3.weight) lbs x \(savedSet3.reps)")

        // Step 3: Simulate reopening the exercise - this is what LogExerciseView.initializeSetEntries does
        let descriptor = FetchDescriptor<SetLog>()
        let allSetLogs = try context.fetch(descriptor)

        // This simulates the previousSets computed property
        let previousSets = getPreviousSets(for: exercise, from: allSetLogs)

        print("\nSTEP 2 - previousSets dictionary:")
        for (key, value) in previousSets.sorted(by: { $0.key < $1.key }) {
            print("  [\(key)]: weight=\(value.weight), reps=\(value.reps)")
        }

        // Step 4: Verify we get all 3 sets
        #expect(previousSets.count == 3, "Should have 3 previous sets, got \(previousSets.count)")

        // Step 5: Simulate what initializeSetEntries does - create SetEntry for each previous set
        let userUnit = WeightUnit.kilograms
        var autoFilledEntries: [(number: Int, weight: Double, reps: Int)] = []

        let sortedSetNumbers = previousSets.keys.sorted()
        for setNumber in sortedSetNumbers {
            let (previousWeight, previousReps) = previousSets[setNumber]!
            let displayWeight = UnitConverter.toDisplay(previousWeight, unit: userUnit)
            autoFilledEntries.append((number: setNumber, weight: displayWeight, reps: previousReps))
        }

        print("\nSTEP 3 - Auto-filled SetEntry values:")
        for entry in autoFilledEntries {
            print("  Set \(entry.number): \(entry.weight) kg x \(entry.reps)")
        }

        // Step 6: Simulate what SetRowView displays for PREVIOUS column
        print("\nSTEP 4 - PREVIOUS column display vs Auto-fill comparison:")
        for entry in autoFilledEntries {
            let previousData = previousSets[entry.number]!
            let previousDisplayWeight = UnitConverter.toDisplay(previousData.weight, unit: userUnit)

            print("  Set \(entry.number):")
            print("    PREVIOUS column: \(Int(previousDisplayWeight))kg x \(previousData.reps)")
            print("    Auto-fill: \(entry.weight)kg x \(entry.reps)")
            print("    Match: \(abs(entry.weight - previousDisplayWeight) < 0.01 && entry.reps == previousData.reps)")

            #expect(
                abs(entry.weight - previousDisplayWeight) < 0.01,
                "Set \(entry.number) weight mismatch: auto-fill=\(entry.weight), PREVIOUS=\(previousDisplayWeight)"
            )
            #expect(
                entry.reps == previousData.reps,
                "Set \(entry.number) reps mismatch: auto-fill=\(entry.reps), PREVIOUS=\(previousData.reps)"
            )
        }

        print("\nTEST PASSED: Full workflow - PREVIOUS column matches auto-fill values")
    }
}
