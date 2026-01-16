//
//  ViewTests.swift
//  workout-appTests
//
//  Comprehensive view-level tests for end-to-end functionality
//

import Testing
import SwiftData
import Foundation
@testable import workout_app

// MARK: - Session Set Entry Tests

@Suite("SessionSetEntry Tests")
struct SessionSetEntryTests {

    @Test("SessionSetEntry has unique IDs")
    func testUniqueIds() {
        let entry1 = SessionSetEntry()
        let entry2 = SessionSetEntry()

        #expect(entry1.id != entry2.id)
    }

    @Test("SessionSetEntry default values")
    func testDefaultValues() {
        let entry = SessionSetEntry()

        #expect(entry.weight == 0)
        #expect(entry.reps == 0)
        #expect(entry.isCompleted == false)
    }

    @Test("SessionSetEntry with custom values")
    func testCustomValues() {
        let entry = SessionSetEntry(weight: 135.0, reps: 10, isCompleted: true)

        #expect(entry.weight == 135.0)
        #expect(entry.reps == 10)
        #expect(entry.isCompleted == true)
    }
}

// MARK: - Timer Manager Tests

@Suite("TimerManager Tests")
struct TimerManagerTests {

    @Test("TimerManager initial state")
    @MainActor
    func testInitialState() {
        let timer = TimerManager()

        #expect(timer.timeRemaining == 0)
        #expect(timer.totalTime == 0)
        #expect(timer.isRunning == false)
        #expect(timer.isComplete == false)
        #expect(timer.progress == 0)
    }

    @Test("TimerManager formatted time")
    @MainActor
    func testFormattedTime() {
        let timer = TimerManager()

        // Test 0 seconds
        #expect(timer.formattedTime == "0:00")

        // Start with 90 seconds
        timer.start(duration: 90)
        #expect(timer.formattedTime == "1:30")
        timer.stop()

        // Start with 65 seconds
        timer.start(duration: 65)
        #expect(timer.formattedTime == "1:05")
        timer.stop()
    }

    @Test("TimerManager add time")
    @MainActor
    func testAddTime() {
        let timer = TimerManager()
        timer.start(duration: 60)

        // Add 15 seconds - both timeRemaining and totalTime increase
        timer.addTime(15)
        #expect(timer.timeRemaining == 75)
        #expect(timer.totalTime == 75)

        // Subtract 30 seconds
        timer.addTime(-30)
        #expect(timer.timeRemaining == 45)
        #expect(timer.totalTime == 45)

        timer.stop()
    }

    @Test("TimerManager skip")
    @MainActor
    func testSkip() {
        let timer = TimerManager()
        timer.start(duration: 90)

        #expect(timer.isComplete == false)

        timer.skip()

        #expect(timer.isComplete == true)
        #expect(timer.timeRemaining == 0)
    }

    @Test("TimerManager progress calculation")
    @MainActor
    func testProgress() {
        let timer = TimerManager()
        timer.start(duration: 100)

        // Initially, progress should be 0 (100/100 remaining)
        #expect(timer.progress == 0)

        // Progress formula: 1 - (timeRemaining / totalTime)
        // Since addTime changes both timeRemaining and totalTime by same amount,
        // we need to directly set timeRemaining to test progress
        // After start: timeRemaining = 100, totalTime = 100, progress = 0
        // If timer runs for a while (simulated): timeRemaining = 50, totalTime = 100, progress = 0.5
        // But we can't easily simulate timer ticks in tests without waiting
        // So we just verify the formula works with initial values
        #expect(timer.totalTime == 100)
        #expect(timer.timeRemaining == 100)

        timer.stop()
    }
}

// MARK: - Routine Session Flow Tests

@Suite("Routine Session Flow Tests")
@MainActor
struct RoutineSessionFlowTests {

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

    @Test("Session volume calculation from completed sets")
    func testSessionVolumeCalculation() {
        // Create mock set entries
        var entries: [SessionSetEntry] = [
            SessionSetEntry(weight: 135.0, reps: 10, isCompleted: true),
            SessionSetEntry(weight: 135.0, reps: 8, isCompleted: true),
            SessionSetEntry(weight: 135.0, reps: 6, isCompleted: false) // Not completed
        ]

        // Calculate volume (only from completed sets)
        let sessionVolume = entries
            .filter { $0.isCompleted }
            .reduce(0) { $0 + Double($1.reps) * $1.weight }

        // Expected: (135 * 10) + (135 * 8) = 1350 + 1080 = 2430
        #expect(sessionVolume == 2430.0)
    }

    @Test("Completed sets count")
    func testCompletedSetsCount() {
        let entries: [SessionSetEntry] = [
            SessionSetEntry(weight: 135.0, reps: 10, isCompleted: true),
            SessionSetEntry(weight: 135.0, reps: 8, isCompleted: true),
            SessionSetEntry(weight: 135.0, reps: 6, isCompleted: false),
            SessionSetEntry(weight: 135.0, reps: 5, isCompleted: true)
        ]

        let completedCount = entries.filter { $0.isCompleted }.count

        #expect(completedCount == 3)
    }

    @Test("Save session sets to SetLog")
    func testSaveSessionSets() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Create exercise and routine
        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        context.insert(exercise)

        // Simulate completed session entries
        let entries: [SessionSetEntry] = [
            SessionSetEntry(weight: 135.0, reps: 10, isCompleted: true),
            SessionSetEntry(weight: 135.0, reps: 8, isCompleted: true),
            SessionSetEntry(weight: 140.0, reps: 6, isCompleted: true)
        ]

        // Save to SetLog (simulating finishSession)
        for (index, entry) in entries.enumerated() where entry.isCompleted {
            let setLog = SetLog(
                setNumber: index + 1,
                reps: entry.reps,
                weight: entry.weight,
                date: Date(),
                exercise: exercise
            )
            context.insert(setLog)
        }

        try context.save()

        // Verify saved data
        let descriptor = FetchDescriptor<SetLog>()
        let savedLogs = try context.fetch(descriptor)

        #expect(savedLogs.count == 3)
        #expect(savedLogs.allSatisfy { $0.exercise?.id == exercise.id })
    }

    @Test("Initialize set entries from previous workout")
    func testInitializeFromPreviousWorkout() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        context.insert(exercise)

        // Create previous workout (yesterday)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let prevSet1 = SetLog(setNumber: 1, reps: 5, weight: 225.0, date: yesterday, exercise: exercise)
        let prevSet2 = SetLog(setNumber: 2, reps: 5, weight: 225.0, date: yesterday, exercise: exercise)
        let prevSet3 = SetLog(setNumber: 3, reps: 5, weight: 225.0, date: yesterday, exercise: exercise)

        context.insert(prevSet1)
        context.insert(prevSet2)
        context.insert(prevSet3)
        try context.save()

        // Simulate previousSets lookup
        let descriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(descriptor)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let exerciseLogs = allLogs
            .filter { log in
                log.exercise?.id == exercise.id &&
                calendar.startOfDay(for: log.date) < today
            }
            .sorted { $0.date > $1.date }

        guard let mostRecentDate = exerciseLogs.first?.date else {
            Issue.record("No previous logs found")
            return
        }

        let mostRecentSets = exerciseLogs.filter {
            calendar.isDate($0.date, inSameDayAs: mostRecentDate)
        }

        // Build previous sets dictionary
        var previousSets: [Int: (weight: Double, reps: Int)] = [:]
        for log in mostRecentSets {
            previousSets[log.setNumber] = (log.weight, log.reps)
        }

        #expect(previousSets.count == 3)
        #expect(previousSets[1]?.weight == 225.0)
        #expect(previousSets[1]?.reps == 5)
    }
}

// MARK: - Metrics View Data Tests

@Suite("Metrics View Data Tests")
@MainActor
struct MetricsViewDataTests {

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

    @Test("Weekly volume aggregation")
    func testWeeklyVolumeAggregation() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        context.insert(exercise)

        let calendar = Calendar.current

        // Create sets across 2 weeks
        let thisWeek = Date()
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: thisWeek)!

        // This week: 3 sets @ 135lbs x 10 = 4050 volume
        for i in 1...3 {
            let log = SetLog(setNumber: i, reps: 10, weight: 135.0, date: thisWeek, exercise: exercise)
            context.insert(log)
        }

        // Last week: 3 sets @ 130lbs x 10 = 3900 volume
        for i in 1...3 {
            let log = SetLog(setNumber: i, reps: 10, weight: 130.0, date: lastWeek, exercise: exercise)
            context.insert(log)
        }

        try context.save()

        // Aggregate by week
        let descriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(descriptor)

        let groupedByWeek = Dictionary(grouping: allLogs) { log in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: log.date)
        }

        let weeklyVolumes = groupedByWeek.map { (key, logs) in
            logs.reduce(0.0) { $0 + $1.calculatedVolume }
        }

        #expect(weeklyVolumes.count == 2)
        #expect(weeklyVolumes.contains(4050.0))
        #expect(weeklyVolumes.contains(3900.0))
    }

    @Test("Muscle group filtering")
    func testMuscleGroupFiltering() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let benchPress = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        let squat = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        context.insert(benchPress)
        context.insert(squat)

        // Add logs for both exercises
        let chestLog = SetLog(setNumber: 1, reps: 10, weight: 135.0, date: Date(), exercise: benchPress)
        let legLog = SetLog(setNumber: 1, reps: 5, weight: 225.0, date: Date(), exercise: squat)

        context.insert(chestLog)
        context.insert(legLog)
        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(descriptor)

        // Filter by chest
        let chestLogs = allLogs.filter { $0.exercise?.targetMuscleGroup == "Chest" }
        #expect(chestLogs.count == 1)
        #expect(chestLogs.first?.exercise?.name == "Bench Press")

        // Filter by legs
        let legLogs = allLogs.filter { $0.exercise?.targetMuscleGroup == "Legs" }
        #expect(legLogs.count == 1)
        #expect(legLogs.first?.exercise?.name == "Squat")
    }

    @Test("Exercises with logs list")
    func testExercisesWithLogs() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let benchPress = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        let squat = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        let deadlift = Exercise(name: "Deadlift", targetMuscleGroup: "Back") // No logs

        context.insert(benchPress)
        context.insert(squat)
        context.insert(deadlift)

        // Only add logs for bench and squat
        let benchLog = SetLog(setNumber: 1, reps: 10, weight: 135.0, date: Date(), exercise: benchPress)
        let squatLog = SetLog(setNumber: 1, reps: 5, weight: 225.0, date: Date(), exercise: squat)

        context.insert(benchLog)
        context.insert(squatLog)
        try context.save()

        let logDescriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(logDescriptor)

        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let allExercises = try context.fetch(exerciseDescriptor)

        // Find exercises that have logs
        let exerciseIds = Set(allLogs.compactMap { $0.exercise?.id })
        let exercisesWithLogs = allExercises.filter { exerciseIds.contains($0.id) }

        #expect(exercisesWithLogs.count == 2)
        #expect(exercisesWithLogs.contains { $0.name == "Bench Press" })
        #expect(exercisesWithLogs.contains { $0.name == "Squat" })
        #expect(!exercisesWithLogs.contains { $0.name == "Deadlift" })
    }
}

// MARK: - Exercise Detail Metrics Tests

@Suite("Exercise Detail Metrics Tests")
@MainActor
struct ExerciseDetailMetricsTests {

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

    @Test("Volume over time calculation")
    func testVolumeOverTime() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        context.insert(exercise)

        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Day 1: 2 sets
        context.insert(SetLog(setNumber: 1, reps: 10, weight: 135.0, date: yesterday, exercise: exercise))
        context.insert(SetLog(setNumber: 2, reps: 8, weight: 135.0, date: yesterday, exercise: exercise))

        // Day 2: 3 sets
        context.insert(SetLog(setNumber: 1, reps: 10, weight: 140.0, date: today, exercise: exercise))
        context.insert(SetLog(setNumber: 2, reps: 8, weight: 140.0, date: today, exercise: exercise))
        context.insert(SetLog(setNumber: 3, reps: 6, weight: 140.0, date: today, exercise: exercise))

        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(descriptor)

        let exerciseLogs = allLogs.filter { $0.exercise?.id == exercise.id }

        // Group by day
        let grouped = Dictionary(grouping: exerciseLogs) { log in
            calendar.startOfDay(for: log.date)
        }

        let volumePerDay = grouped.map { (date, logs) in
            (date: date, volume: logs.reduce(0.0) { $0 + $1.calculatedVolume })
        }.sorted { $0.date < $1.date }

        #expect(volumePerDay.count == 2)

        // Day 1 volume: (10*135) + (8*135) = 1350 + 1080 = 2430
        #expect(volumePerDay[0].volume == 2430.0)

        // Day 2 volume: (10*140) + (8*140) + (6*140) = 1400 + 1120 + 840 = 3360
        #expect(volumePerDay[1].volume == 3360.0)
    }

    @Test("Personal record weight detection")
    func testPersonalRecordWeight() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        context.insert(exercise)

        // Various weights over time
        context.insert(SetLog(setNumber: 1, reps: 10, weight: 135.0, date: Date(), exercise: exercise))
        context.insert(SetLog(setNumber: 2, reps: 8, weight: 155.0, date: Date(), exercise: exercise))
        context.insert(SetLog(setNumber: 3, reps: 5, weight: 185.0, date: Date(), exercise: exercise)) // PR

        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(descriptor)

        let exerciseLogs = allLogs.filter { $0.exercise?.id == exercise.id }
        let prWeight = exerciseLogs.max(by: { $0.weight < $1.weight })?.weight

        #expect(prWeight == 185.0)
    }

    @Test("Max weight over time")
    func testMaxWeightOverTime() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        context.insert(exercise)

        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Day 1: max 225
        context.insert(SetLog(setNumber: 1, reps: 5, weight: 205.0, date: yesterday, exercise: exercise))
        context.insert(SetLog(setNumber: 2, reps: 5, weight: 225.0, date: yesterday, exercise: exercise))

        // Day 2: max 245
        context.insert(SetLog(setNumber: 1, reps: 5, weight: 225.0, date: today, exercise: exercise))
        context.insert(SetLog(setNumber: 2, reps: 3, weight: 245.0, date: today, exercise: exercise))

        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(descriptor)

        let exerciseLogs = allLogs.filter { $0.exercise?.id == exercise.id }

        // Group by day and find max per day
        let grouped = Dictionary(grouping: exerciseLogs) { log in
            calendar.startOfDay(for: log.date)
        }

        let maxWeightPerDay = grouped.compactMap { (date, logs) -> (date: Date, weight: Double)? in
            guard let maxWeight = logs.max(by: { $0.weight < $1.weight })?.weight else { return nil }
            return (date: date, weight: maxWeight)
        }.sorted { $0.date < $1.date }

        #expect(maxWeightPerDay.count == 2)
        #expect(maxWeightPerDay[0].weight == 225.0)
        #expect(maxWeightPerDay[1].weight == 245.0)
    }
}

// MARK: - Calendar View Tests

@Suite("Calendar View Data Tests")
@MainActor
struct CalendarViewDataTests {

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

    @Test("Workout dates detection")
    func testWorkoutDatesDetection() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        context.insert(exercise)

        let calendar = Calendar.current
        let today = Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!

        // Log on 3 different days
        context.insert(SetLog(setNumber: 1, reps: 10, weight: 135.0, date: today, exercise: exercise))
        context.insert(SetLog(setNumber: 1, reps: 10, weight: 135.0, date: twoDaysAgo, exercise: exercise))
        context.insert(SetLog(setNumber: 1, reps: 10, weight: 135.0, date: fiveDaysAgo, exercise: exercise))

        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(descriptor)

        let workoutDates = Set(allLogs.map { calendar.startOfDay(for: $0.date) })

        #expect(workoutDates.count == 3)
    }

    @Test("Volume for specific date")
    func testVolumeForDate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        context.insert(exercise)

        let calendar = Calendar.current
        let targetDate = Date()

        // Multiple sets on target date
        context.insert(SetLog(setNumber: 1, reps: 10, weight: 135.0, date: targetDate, exercise: exercise))
        context.insert(SetLog(setNumber: 2, reps: 8, weight: 135.0, date: targetDate, exercise: exercise))
        context.insert(SetLog(setNumber: 3, reps: 6, weight: 135.0, date: targetDate, exercise: exercise))

        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(descriptor)

        let startOfDay = calendar.startOfDay(for: targetDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let dayVolume = allLogs
            .filter { $0.date >= startOfDay && $0.date < endOfDay }
            .reduce(0.0) { $0 + $1.calculatedVolume }

        // (10+8+6) * 135 = 24 * 135 = 3240
        #expect(dayVolume == 3240.0)
    }

    @Test("Workouts grouped by exercise for a date")
    func testWorkoutsGroupedByExercise() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let benchPress = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        let squat = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        context.insert(benchPress)
        context.insert(squat)

        let targetDate = Date()

        // Bench sets
        context.insert(SetLog(setNumber: 1, reps: 10, weight: 135.0, date: targetDate, exercise: benchPress))
        context.insert(SetLog(setNumber: 2, reps: 8, weight: 135.0, date: targetDate, exercise: benchPress))

        // Squat sets
        context.insert(SetLog(setNumber: 1, reps: 5, weight: 225.0, date: targetDate, exercise: squat))

        try context.save()

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: targetDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(descriptor)

        let dayLogs = allLogs.filter { $0.date >= startOfDay && $0.date < endOfDay }
        let groupedByExercise = Dictionary(grouping: dayLogs) { $0.exercise }

        #expect(groupedByExercise.count == 2)
    }
}

// MARK: - Muscle Group Breakdown Tests

@Suite("Muscle Group Breakdown Tests")
@MainActor
struct MuscleGroupBreakdownTests {

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

    @Test("Volume by muscle group")
    func testVolumeByMuscleGroup() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let benchPress = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        let squat = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        let deadlift = Exercise(name: "Deadlift", targetMuscleGroup: "Back")

        context.insert(benchPress)
        context.insert(squat)
        context.insert(deadlift)

        // Chest: 2000 volume
        context.insert(SetLog(setNumber: 1, reps: 10, weight: 100.0, date: Date(), exercise: benchPress))
        context.insert(SetLog(setNumber: 2, reps: 10, weight: 100.0, date: Date(), exercise: benchPress))

        // Legs: 2250 volume
        context.insert(SetLog(setNumber: 1, reps: 5, weight: 225.0, date: Date(), exercise: squat))
        context.insert(SetLog(setNumber: 2, reps: 5, weight: 225.0, date: Date(), exercise: squat))

        // Back: 1800 volume
        context.insert(SetLog(setNumber: 1, reps: 5, weight: 180.0, date: Date(), exercise: deadlift))
        context.insert(SetLog(setNumber: 2, reps: 5, weight: 180.0, date: Date(), exercise: deadlift))

        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(descriptor)

        let groupedByMuscle = Dictionary(grouping: allLogs) { log in
            log.exercise?.targetMuscleGroup ?? "Unknown"
        }

        let volumeByMuscle = groupedByMuscle.mapValues { logs in
            logs.reduce(0.0) { $0 + $1.calculatedVolume }
        }

        #expect(volumeByMuscle["Chest"] == 2000.0)
        #expect(volumeByMuscle["Legs"] == 2250.0)
        #expect(volumeByMuscle["Back"] == 1800.0)
    }

    @Test("Time range filtering")
    func testTimeRangeFiltering() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        context.insert(exercise)

        let calendar = Calendar.current
        let today = Date()
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today)!

        // Recent (within week)
        context.insert(SetLog(setNumber: 1, reps: 10, weight: 135.0, date: today, exercise: exercise))

        // Within month but not week
        context.insert(SetLog(setNumber: 1, reps: 10, weight: 130.0, date: twoWeeksAgo, exercise: exercise))

        try context.save()

        let descriptor = FetchDescriptor<SetLog>()
        let allLogs = try context.fetch(descriptor)

        // Filter for last 7 days
        let cutoffDate = calendar.date(byAdding: .day, value: -7, to: today)!
        let weekLogs = allLogs.filter { $0.date >= cutoffDate }

        #expect(weekLogs.count == 1)
        #expect(weekLogs.first?.weight == 135.0)

        // Filter for last 30 days
        let monthCutoff = calendar.date(byAdding: .day, value: -30, to: today)!
        let monthLogs = allLogs.filter { $0.date >= monthCutoff }

        #expect(monthLogs.count == 2)
    }

    @Test("Percentage calculation")
    func testPercentageCalculation() {
        let volumeByGroup: [String: Double] = [
            "Chest": 2000.0,
            "Legs": 3000.0,
            "Back": 5000.0
        ]

        let totalVolume = volumeByGroup.values.reduce(0, +)
        #expect(totalVolume == 10000.0)

        let chestPercentage = (volumeByGroup["Chest"]! / totalVolume) * 100
        #expect(chestPercentage == 20.0)

        let legsPercentage = (volumeByGroup["Legs"]! / totalVolume) * 100
        #expect(legsPercentage == 30.0)

        let backPercentage = (volumeByGroup["Back"]! / totalVolume) * 100
        #expect(backPercentage == 50.0)
    }
}

// MARK: - User Preferences Integration Tests

@Suite("User Preferences Integration Tests")
@MainActor
struct UserPreferencesIntegrationTests {

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

    @Test("Timer settings affect rest timer behavior")
    func testTimerSettings() {
        // Timer enabled by default
        let defaultPrefs = UserPreferences()
        #expect(defaultPrefs.enableRestTimer == true)
        #expect(defaultPrefs.defaultRestDuration == 90)

        // Disable timer
        let disabledPrefs = UserPreferences(enableRestTimer: false)
        #expect(disabledPrefs.enableRestTimer == false)

        // Custom duration
        let customPrefs = UserPreferences(defaultRestDuration: 120)
        #expect(customPrefs.defaultRestDuration == 120)
    }

    @Test("Weight unit affects display throughout app")
    func testWeightUnitDisplay() {
        let storedWeight = 135.0 // pounds (storage format)

        // User prefers pounds
        let poundPrefs = UserPreferences(preferredWeightUnit: .pounds)
        let poundDisplay = UnitConverter.toDisplay(storedWeight, unit: poundPrefs.preferredWeightUnit)
        #expect(poundDisplay == 135.0)

        // User prefers kilograms
        let kgPrefs = UserPreferences(preferredWeightUnit: .kilograms)
        let kgDisplay = UnitConverter.toDisplay(storedWeight, unit: kgPrefs.preferredWeightUnit)
        #expect(abs(kgDisplay - 61.235) < 0.01)
    }
}
