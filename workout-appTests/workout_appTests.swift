//
//  workout_appTests.swift
//  workout-appTests
//
//  Created by Rahul Bharti on 28/11/25.
//

import Testing
import Foundation
import SwiftData
@testable import workout_app

// MARK: - UnitConverter Tests

struct UnitConverterTests {

    @Test("Convert kilograms to pounds")
    func testKgToLbs() async throws {
        // Test basic conversion
        let result = UnitConverter.kgToLbs(10.0)
        #expect(abs(result - 22.0462262) < 0.0001)

        // Test zero
        #expect(UnitConverter.kgToLbs(0.0) == 0.0)

        // Test fractional values
        let fractional = UnitConverter.kgToLbs(2.5)
        #expect(abs(fractional - 5.51155655) < 0.0001)
    }

    @Test("Convert pounds to kilograms")
    func testLbsToKg() async throws {
        // Test basic conversion
        let result = UnitConverter.lbsToKg(22.0462262)
        #expect(abs(result - 10.0) < 0.0001)

        // Test zero
        #expect(UnitConverter.lbsToKg(0.0) == 0.0)

        // Test fractional values
        let fractional = UnitConverter.lbsToKg(5.51155655)
        #expect(abs(fractional - 2.5) < 0.0001)
    }

    @Test("Convert weight between units")
    func testConvertBetweenUnits() async throws {
        // Test pounds to kg
        let lbsToKg = UnitConverter.convert(100.0, from: .pounds, to: .kilograms)
        #expect(abs(lbsToKg - 45.359237) < 0.0001)

        // Test kg to pounds
        let kgToLbs = UnitConverter.convert(50.0, from: .kilograms, to: .pounds)
        #expect(abs(kgToLbs - 110.231131) < 0.0001)

        // Test same unit conversion (should return same value)
        #expect(UnitConverter.convert(100.0, from: .pounds, to: .pounds) == 100.0)
        #expect(UnitConverter.convert(50.0, from: .kilograms, to: .kilograms) == 50.0)
    }

    @Test("Convert to display format")
    func testToDisplay() async throws {
        let weightInPounds = 100.0

        // Display in pounds (no conversion needed)
        let displayLbs = UnitConverter.toDisplay(weightInPounds, unit: .pounds)
        #expect(displayLbs == 100.0)

        // Display in kilograms
        let displayKg = UnitConverter.toDisplay(weightInPounds, unit: .kilograms)
        #expect(abs(displayKg - 45.359237) < 0.0001)
    }

    @Test("Convert to storage format")
    func testToStorage() async throws {
        // From pounds (no conversion)
        let fromLbs = UnitConverter.toStorage(100.0, from: .pounds)
        #expect(fromLbs == 100.0)

        // From kilograms
        let fromKg = UnitConverter.toStorage(50.0, from: .kilograms)
        #expect(abs(fromKg - 110.231131) < 0.0001)
    }

    @Test("Format weight for display")
    func testDisplayWeight() async throws {
        let weight = 100.0 // in pounds (storage format)

        // Format in pounds
        let lbsDisplay = UnitConverter.displayWeight(weight, in: .pounds)
        #expect(lbsDisplay == "100.0 lbs")

        // Format in kilograms
        let kgDisplay = UnitConverter.displayWeight(weight, in: .kilograms)
        #expect(kgDisplay == "45.4 kg")

        // Test with different decimal places
        let detailedDisplay = UnitConverter.displayWeight(weight, in: .kilograms, decimals: 2)
        #expect(detailedDisplay == "45.36 kg")
    }

    @Test("Format weight value only")
    func testDisplayValue() async throws {
        let weight = 135.0 // in pounds

        let lbsValue = UnitConverter.displayValue(weight, in: .pounds)
        #expect(lbsValue == "135.0")

        let kgValue = UnitConverter.displayValue(weight, in: .kilograms, decimals: 2)
        #expect(kgValue == "61.23")
    }

    @Test("Format detailed display")
    func testDetailedDisplay() async throws {
        let weight = 200.0 // in pounds

        let lbsDetailed = UnitConverter.detailedDisplay(weight, in: .pounds)
        #expect(lbsDetailed == "200.00 Pounds (lbs)")

        let kgDetailed = UnitConverter.detailedDisplay(weight, in: .kilograms)
        #expect(kgDetailed == "90.72 Kilograms (kg)")
    }

    @Test("Round-trip conversion accuracy")
    func testRoundTripConversion() async throws {
        let original = 100.0

        // Convert lbs -> kg -> lbs
        let toKg = UnitConverter.lbsToKg(original)
        let backToLbs = UnitConverter.kgToLbs(toKg)
        #expect(abs(backToLbs - original) < 0.0001)

        // Convert kg -> lbs -> kg
        let toLbs = UnitConverter.kgToLbs(original)
        let backToKg = UnitConverter.lbsToKg(toLbs)
        #expect(abs(backToKg - original) < 0.0001)
    }
}

// MARK: - WeightUnit Tests

struct WeightUnitTests {

    @Test("WeightUnit raw values")
    func testRawValues() async throws {
        #expect(WeightUnit.pounds.rawValue == "lbs")
        #expect(WeightUnit.kilograms.rawValue == "kg")
    }

    @Test("WeightUnit display names")
    func testDisplayNames() async throws {
        #expect(WeightUnit.pounds.displayName == "Pounds (lbs)")
        #expect(WeightUnit.kilograms.displayName == "Kilograms (kg)")
    }

    @Test("WeightUnit abbreviations")
    func testAbbreviations() async throws {
        #expect(WeightUnit.pounds.abbreviation == "lbs")
        #expect(WeightUnit.kilograms.abbreviation == "kg")
    }

    @Test("WeightUnit codable")
    func testCodable() async throws {
        // Test encoding
        let encoder = JSONEncoder()
        let poundsData = try encoder.encode(WeightUnit.pounds)
        let kgData = try encoder.encode(WeightUnit.kilograms)

        // Test decoding
        let decoder = JSONDecoder()
        let decodedPounds = try decoder.decode(WeightUnit.self, from: poundsData)
        let decodedKg = try decoder.decode(WeightUnit.self, from: kgData)

        #expect(decodedPounds == .pounds)
        #expect(decodedKg == .kilograms)
    }
}

// MARK: - UserPreferences Tests

@Suite("UserPreferences Model Tests")
struct UserPreferencesTests {

    @Test("UserPreferences initialization with defaults")
    func testDefaultInitialization() async throws {
        let prefs = UserPreferences()

        #expect(prefs.id == "singleton")
        #expect(prefs.preferredWeightUnit == .pounds)
        #expect(prefs.enableRestTimer == true)
        #expect(prefs.defaultRestDuration == 90)
    }

    @Test("UserPreferences initialization with custom values")
    func testCustomInitialization() async throws {
        let prefs = UserPreferences(
            preferredWeightUnit: .kilograms,
            enableRestTimer: false,
            defaultRestDuration: 120
        )

        #expect(prefs.id == "singleton")
        #expect(prefs.preferredWeightUnit == .kilograms)
        #expect(prefs.enableRestTimer == false)
        #expect(prefs.defaultRestDuration == 120)
    }

    @Test("UserPreferences has unique singleton ID")
    func testSingletonId() async throws {
        let prefs1 = UserPreferences()
        let prefs2 = UserPreferences()

        // Both should have the same ID to ensure singleton behavior
        #expect(prefs1.id == prefs2.id)
        #expect(prefs1.id == "singleton")
    }
}

// MARK: - Exercise Model Tests

@Suite("Exercise Model Tests")
struct ExerciseModelTests {

    @Test("Exercise initialization")
    func testExerciseInitialization() async throws {
        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")

        #expect(exercise.name == "Bench Press")
        #expect(exercise.targetMuscleGroup == "Chest")
        #expect(exercise.logs != nil)
        #expect(exercise.logs?.isEmpty == true)
    }

    @Test("Exercise has unique UUID")
    func testExerciseUniqueId() async throws {
        let exercise1 = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        let exercise2 = Exercise(name: "Squat", targetMuscleGroup: "Legs")

        // Each exercise should have a unique UUID
        #expect(exercise1.id != exercise2.id)
    }

    @Test("Exercise with various muscle groups")
    func testExerciseMuscleGroups() async throws {
        let exerciseGroups = [
            ("Bench Press", "Chest"),
            ("Squat", "Legs"),
            ("Deadlift", "Back"),
            ("Overhead Press", "Shoulders"),
            ("Bicep Curl", "Arms"),
            ("Plank", "Core"),
            ("Running", "Cardio")
        ]

        for (name, group) in exerciseGroups {
            let exercise = Exercise(name: name, targetMuscleGroup: group)
            #expect(exercise.name == name)
            #expect(exercise.targetMuscleGroup == group)
        }
    }
}

// MARK: - WorkoutLog Model Tests

@Suite("WorkoutLog Model Tests")
struct WorkoutLogModelTests {

    @Test("WorkoutLog initialization")
    func testWorkoutLogInitialization() async throws {
        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        let date = Date()
        let log = WorkoutLog(
            date: date,
            sets: 3,
            reps: 10,
            weight: 135.0,
            exercise: exercise
        )

        #expect(log.date == date)
        #expect(log.sets == 3)
        #expect(log.reps == 10)
        #expect(log.weight == 135.0)
        #expect(log.exercise?.name == "Bench Press")
    }

    @Test("WorkoutLog volume calculation")
    func testVolumeCalculation() async throws {
        let exercise = Exercise(name: "Squat", targetMuscleGroup: "Legs")

        // Test case 1: 3 sets x 10 reps x 100 lbs = 3000 lbs
        let log1 = WorkoutLog(date: Date(), sets: 3, reps: 10, weight: 100.0, exercise: exercise)
        #expect(log1.calculatedVolume == 3000.0)

        // Test case 2: 5 sets x 5 reps x 200 lbs = 5000 lbs
        let log2 = WorkoutLog(date: Date(), sets: 5, reps: 5, weight: 200.0, exercise: exercise)
        #expect(log2.calculatedVolume == 5000.0)

        // Test case 3: 4 sets x 12 reps x 50 lbs = 2400 lbs
        let log3 = WorkoutLog(date: Date(), sets: 4, reps: 12, weight: 50.0, exercise: exercise)
        #expect(log3.calculatedVolume == 2400.0)
    }

    @Test("WorkoutLog with zero values")
    func testWorkoutLogZeroValues() async throws {
        let exercise = Exercise(name: "Test", targetMuscleGroup: "Test")
        let log = WorkoutLog(date: Date(), sets: 0, reps: 0, weight: 0.0, exercise: exercise)

        #expect(log.calculatedVolume == 0.0)
    }

    @Test("WorkoutLog with decimal weight")
    func testWorkoutLogDecimalWeight() async throws {
        let exercise = Exercise(name: "Dumbbell Curl", targetMuscleGroup: "Arms")
        let log = WorkoutLog(date: Date(), sets: 3, reps: 12, weight: 22.5, exercise: exercise)

        // 3 x 12 x 22.5 = 810.0
        #expect(log.calculatedVolume == 810.0)
    }

    @Test("WorkoutLog has unique UUID")
    func testWorkoutLogUniqueId() async throws {
        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        let log1 = WorkoutLog(date: Date(), sets: 3, reps: 10, weight: 135.0, exercise: exercise)
        let log2 = WorkoutLog(date: Date(), sets: 3, reps: 10, weight: 135.0, exercise: exercise)

        #expect(log1.id != log2.id)
    }
}

// MARK: - Routine Model Tests

@Suite("Routine Model Tests")
struct RoutineModelTests {

    @Test("Routine initialization with no exercises")
    func testRoutineEmptyInitialization() async throws {
        let routine = Routine(dayOfWeek: "Monday")

        #expect(routine.dayOfWeek == "Monday")
        #expect(routine.exercises.isEmpty)
    }

    @Test("Routine initialization with exercises")
    func testRoutineWithExercises() async throws {
        let ex1 = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        let ex2 = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        let exercises = [ex1, ex2]

        let routine = Routine(dayOfWeek: "Tuesday", exercises: exercises)

        #expect(routine.dayOfWeek == "Tuesday")
        #expect(routine.exercises.count == 2)
        #expect(routine.exercises[0].name == "Bench Press")
        #expect(routine.exercises[1].name == "Squat")
    }

    @Test("Routine for all days of week")
    func testRoutineForAllDays() async throws {
        let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        for day in daysOfWeek {
            let routine = Routine(dayOfWeek: day)
            #expect(routine.dayOfWeek == day)
        }
    }

    @Test("Routine with multiple exercises")
    func testRoutineWithManyExercises() async throws {
        let exercises = [
            Exercise(name: "Bench Press", targetMuscleGroup: "Chest"),
            Exercise(name: "Incline Press", targetMuscleGroup: "Chest"),
            Exercise(name: "Dumbbell Fly", targetMuscleGroup: "Chest"),
            Exercise(name: "Tricep Dip", targetMuscleGroup: "Arms")
        ]

        let routine = Routine(dayOfWeek: "Monday", exercises: exercises)

        #expect(routine.exercises.count == 4)
        #expect(routine.exercises.allSatisfy { $0.targetMuscleGroup == "Chest" || $0.targetMuscleGroup == "Arms" })
    }
}

// MARK: - DatabaseSeeder Tests

@Suite("DatabaseSeeder Tests")
struct DatabaseSeederTests {

    @Test("ExerciseData is properly codable")
    func testExerciseDataCodable() async throws {
        let exerciseData = ExerciseData(
            name: "Bench Press",
            targetMuscleGroup: "Chest",
            instructions: "Lie on bench and press weight up",
            formCues: nil,
            videoURL: nil
        )

        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(exerciseData)

        // Test decoding
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ExerciseData.self, from: data)

        #expect(decoded.name == "Bench Press")
        #expect(decoded.targetMuscleGroup == "Chest")
        #expect(decoded.instructions == "Lie on bench and press weight up")
    }

    @Test("ExerciseData with nil instructions")
    func testExerciseDataNilInstructions() async throws {
        let exerciseData = ExerciseData(
            name: "Squat",
            targetMuscleGroup: "Legs",
            instructions: nil,
            formCues: nil,
            videoURL: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(exerciseData)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ExerciseData.self, from: data)

        #expect(decoded.name == "Squat")
        #expect(decoded.targetMuscleGroup == "Legs")
        #expect(decoded.instructions == nil)
    }

    @Test("ExerciseData array decoding")
    func testExerciseDataArrayDecoding() async throws {
        let jsonString = """
        [
            {
                "name": "Bench Press",
                "targetMuscleGroup": "Chest",
                "instructions": "Press the weight"
            },
            {
                "name": "Squat",
                "targetMuscleGroup": "Legs"
            }
        ]
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let exercises = try decoder.decode([ExerciseData].self, from: data)

        #expect(exercises.count == 2)
        #expect(exercises[0].name == "Bench Press")
        #expect(exercises[0].targetMuscleGroup == "Chest")
        #expect(exercises[0].instructions != nil)
        #expect(exercises[1].name == "Squat")
        #expect(exercises[1].targetMuscleGroup == "Legs")
        #expect(exercises[1].instructions == nil)
    }
}

// MARK: - Integration Tests

@Suite("Phase 1 Integration Tests")
struct Phase1IntegrationTests {

    @Test("Complete unit conversion workflow")
    func testCompleteUnitConversionWorkflow() async throws {
        // Create a workout log with weight in pounds (storage format)
        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        let log = WorkoutLog(date: Date(), sets: 3, reps: 10, weight: 135.0, exercise: exercise)

        // User prefers kilograms
        let prefs = UserPreferences(preferredWeightUnit: .kilograms)

        // Display weight in user's preferred unit
        let displayedWeight = UnitConverter.toDisplay(log.weight, unit: prefs.preferredWeightUnit)
        #expect(abs(displayedWeight - 61.235) < 0.001)

        // Format for display
        let formatted = UnitConverter.displayWeight(log.weight, in: prefs.preferredWeightUnit)
        #expect(formatted == "61.2 kg")
    }

    @Test("Exercise logging and volume tracking")
    func testExerciseLoggingAndVolume() async throws {
        let exercise = Exercise(name: "Deadlift", targetMuscleGroup: "Back")

        // Create multiple workout logs
        let log1 = WorkoutLog(date: Date(), sets: 5, reps: 5, weight: 225.0, exercise: exercise)
        let log2 = WorkoutLog(date: Date(), sets: 3, reps: 8, weight: 185.0, exercise: exercise)

        // Verify volumes
        #expect(log1.calculatedVolume == 5625.0) // 5 * 5 * 225
        #expect(log2.calculatedVolume == 4440.0) // 3 * 8 * 185

        // Total volume across workouts
        let totalVolume = log1.calculatedVolume + log2.calculatedVolume
        #expect(totalVolume == 10065.0)
    }

    @Test("Routine with mixed muscle groups")
    func testRoutineWithMixedMuscleGroups() async throws {
        let exercises = [
            Exercise(name: "Bench Press", targetMuscleGroup: "Chest"),
            Exercise(name: "Barbell Row", targetMuscleGroup: "Back"),
            Exercise(name: "Overhead Press", targetMuscleGroup: "Shoulders")
        ]

        let routine = Routine(dayOfWeek: "Monday", exercises: exercises)

        // Verify all exercises are in the routine
        #expect(routine.exercises.count == 3)

        // Verify muscle group diversity
        let muscleGroups = Set(routine.exercises.map { $0.targetMuscleGroup })
        #expect(muscleGroups.count == 3) // Chest, Back, Shoulders
    }

    @Test("Weight unit preference workflow")
    func testWeightUnitPreferenceWorkflow() async throws {
        // User starts with pounds
        var prefs = UserPreferences(preferredWeightUnit: .pounds)

        // Log a workout in pounds
        let exercise = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        let loggedWeight = 225.0
        let storedWeight = UnitConverter.toStorage(loggedWeight, from: prefs.preferredWeightUnit)

        let log = WorkoutLog(date: Date(), sets: 5, reps: 5, weight: storedWeight, exercise: exercise)
        #expect(log.weight == 225.0)

        // User switches to kilograms
        prefs = UserPreferences(preferredWeightUnit: .kilograms)

        // Display the same workout in kilograms
        let displayInKg = UnitConverter.toDisplay(log.weight, unit: prefs.preferredWeightUnit)
        #expect(abs(displayInKg - 102.058) < 0.001)
    }
}
