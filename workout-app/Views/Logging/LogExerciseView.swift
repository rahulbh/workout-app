//
//  LogExerciseView.swift
//  workout-app
//
//  Redesigned to match modern workout logging UX
//

import SwiftUI
import SwiftData

struct LogExerciseView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query private var preferences: [UserPreferences]
    @Query private var allSetLogs: [SetLog]
    @Query private var allWorkoutLogs: [WorkoutLog]  // Fallback for migration

    @State private var setEntries: [SetEntry] = []
    @State private var notes: String = ""
    @State private var hasInitialized = false
    @State private var cachedPreviousSets: [Int: (weight: Double, reps: Int)] = [:]
    @State private var showRestTimer = false

    private var userPreferences: UserPreferences {
        preferences.first ?? UserPreferences()
    }

    // Get previous workout data for this exercise
    private var previousSets: [Int: (weight: Double, reps: Int)] {
        // First, try to get SetLog data (new format)
        let exerciseSetLogs = allSetLogs
            .filter { $0.exercise?.id == exercise.id }
            .sorted { $0.date > $1.date }

        print("DEBUG: Found \(exerciseSetLogs.count) SetLogs for exercise \(exercise.name)")

        if !exerciseSetLogs.isEmpty {
            // Get the most recent workout timestamp
            let lastWorkoutDate = exerciseSetLogs.first!.date

            // Find all sets from the same workout session
            // Sets logged together will have timestamps within a few seconds of each other
            // Use a 5-minute window to group sets from the same session
            let sessionWindow: TimeInterval = 5 * 60 // 5 minutes

            let lastWorkoutSets = exerciseSetLogs.filter { setLog in
                abs(setLog.date.timeIntervalSince(lastWorkoutDate)) < sessionWindow
            }

            print("DEBUG: Last workout session sets count: \(lastWorkoutSets.count) (within \(sessionWindow)s of \(lastWorkoutDate))")

            // Map set number to weight/reps - since we're sorted by date DESC,
            // the first occurrence of each set number is the most recent
            var result: [Int: (weight: Double, reps: Int)] = [:]
            for setLog in lastWorkoutSets {
                // Only set if not already set (first occurrence = most recent)
                if result[setLog.setNumber] == nil {
                    result[setLog.setNumber] = (weight: setLog.weight, reps: setLog.reps)
                    print("DEBUG: Mapped setNumber \(setLog.setNumber) -> weight: \(setLog.weight), reps: \(setLog.reps)")
                }
            }
            print("DEBUG: previousSets result: \(result)")
            return result
        }

        // Fallback: Check old WorkoutLog format for backward compatibility
        let exerciseWorkoutLogs = allWorkoutLogs
            .filter { $0.exercise?.id == exercise.id }
            .sorted { $0.date > $1.date }

        print("DEBUG: Fallback - Found \(exerciseWorkoutLogs.count) WorkoutLogs")

        guard let lastWorkout = exerciseWorkoutLogs.first else { return [:] }

        // For old WorkoutLog format, replicate the same data for each set
        var result: [Int: (weight: Double, reps: Int)] = [:]
        for i in 1...lastWorkout.sets {
            result[i] = (weight: lastWorkout.weight, reps: lastWorkout.reps)
        }
        print("DEBUG: WorkoutLog fallback result: \(result)")
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Exercise Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(exercise.name)
                                .font(.title2)
                                .bold()
                            Spacer()
                        }

                        // Notes section
                        TextField("Add notes here...", text: $notes)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))

                    Divider()

                    // Set Table Header
                    HStack(spacing: 12) {
                        Text("SET")
                            .frame(width: 40, alignment: .leading)
                        Text("PREVIOUS")
                            .frame(width: 90, alignment: .leading)
                        Text(userPreferences.preferredWeightUnit.abbreviation.uppercased())
                            .frame(width: 70, alignment: .center)
                        Text("REPS")
                            .frame(width: 70, alignment: .center)
                        Spacer()
                            .frame(width: 44)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGroupedBackground))

                    // Set Rows
                    ForEach(setEntries) { entry in
                        SetRowView(
                            entry: entry,
                            previousData: cachedPreviousSets[entry.number],
                            unit: userPreferences.preferredWeightUnit,
                            onComplete: { completeSet(entry) },
                            onWeightChange: { updateWeight(for: entry, weight: $0) },
                            onRepsChange: { updateReps(for: entry, reps: $0) }
                        )
                        Divider()
                            .padding(.leading, 16)
                    }

                    // Add Set Button
                    Button(action: addSet) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Set")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                print("DEBUG onAppear: allSetLogs.count = \(allSetLogs.count)")
                initializeSetEntries()
            }
            .onChange(of: allSetLogs) { oldValue, newValue in
                // @Query data may arrive after onAppear, so re-initialize if we haven't yet
                // and new data has arrived
                print("DEBUG onChange: oldCount=\(oldValue.count), newCount=\(newValue.count), hasInitialized=\(hasInitialized)")
                if !hasInitialized || (oldValue.isEmpty && !newValue.isEmpty) {
                    hasInitialized = false  // Reset to allow re-initialization
                    initializeSetEntries()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Finish") {
                        finishWorkout()
                    }
                    .bold()
                    .disabled(setEntries.filter { $0.isCompleted }.isEmpty)
                }
            }
            .sheet(isPresented: $showRestTimer) {
                RestTimerView(duration: TimeInterval(userPreferences.defaultRestDuration))
            }
        }
    }

    private func initializeSetEntries() {
        guard !hasInitialized else { return }
        hasInitialized = true

        // Cache previousSets at initialization time to ensure consistency
        // between auto-fill values and PREVIOUS column display
        cachedPreviousSets = previousSets

        print("DEBUG initializeSetEntries: cachedPreviousSets = \(cachedPreviousSets)")

        // If there's previous workout data, auto-populate sets
        if !cachedPreviousSets.isEmpty {
            let sortedSetNumbers = cachedPreviousSets.keys.sorted()
            print("DEBUG: Sorted set numbers: \(sortedSetNumbers)")
            setEntries = sortedSetNumbers.map { setNumber in
                let (previousWeight, previousReps) = cachedPreviousSets[setNumber]!
                let displayWeight = UnitConverter.toDisplay(previousWeight, unit: userPreferences.preferredWeightUnit)

                print("DEBUG: Creating SetEntry #\(setNumber) with weight: \(displayWeight), reps: \(previousReps)")

                // Pre-fill with previous data
                return SetEntry(
                    number: setNumber,
                    weight: displayWeight,
                    reps: previousReps
                )
            }
            print("DEBUG: Created \(setEntries.count) set entries")
        } else {
            // No previous data, start with one empty set
            print("DEBUG: No previous data, starting with 1 empty set")
            setEntries = [SetEntry(number: 1)]
        }
    }

    private func addSet() {
        let nextSetNumber = (setEntries.last?.number ?? 0) + 1
        setEntries.append(SetEntry(number: nextSetNumber))
    }

    private func updateWeight(for entry: SetEntry, weight: Double) {
        if let index = setEntries.firstIndex(where: { $0.id == entry.id }) {
            setEntries[index].weight = weight
        }
    }

    private func updateReps(for entry: SetEntry, reps: Int) {
        if let index = setEntries.firstIndex(where: { $0.id == entry.id }) {
            setEntries[index].reps = reps
        }
    }

    private func completeSet(_ entry: SetEntry) {
        if let index = setEntries.firstIndex(where: { $0.id == entry.id }) {
            let wasCompleted = setEntries[index].isCompleted
            setEntries[index].isCompleted.toggle()

            // Show rest timer when marking a set as completed (not when uncompleting)
            if !wasCompleted && userPreferences.enableRestTimer {
                showRestTimer = true
            }
        }
    }

    private func finishWorkout() {
        let completedSets = setEntries.filter { $0.isCompleted }
        print("DEBUG finishWorkout: \(completedSets.count) completed sets out of \(setEntries.count) total")

        guard !completedSets.isEmpty else {
            print("DEBUG: No completed sets to save!")
            return
        }

        // Save each completed set as a SetLog
        let currentDate = Date()
        for entry in completedSets {
            let weightInPounds = UnitConverter.toStorage(entry.weight, from: userPreferences.preferredWeightUnit)
            print("DEBUG: Saving SetLog - setNumber: \(entry.number), reps: \(entry.reps), weight: \(weightInPounds)")
            let setLog = SetLog(
                setNumber: entry.number,
                reps: entry.reps,
                weight: weightInPounds,
                notes: entry.notes.isEmpty ? nil : entry.notes,
                date: currentDate,
                exercise: exercise
            )
            modelContext.insert(setLog)
        }

        print("DEBUG: Saved \(completedSets.count) SetLogs")
        dismiss()
    }
}

// MARK: - Set Entry Model
struct SetEntry: Identifiable {
    let id = UUID()
    let number: Int
    var weight: Double = 0
    var reps: Int = 0
    var notes: String = ""
    var isCompleted: Bool = false
}

// MARK: - Set Row View
struct SetRowView: View {
    let entry: SetEntry
    let previousData: (weight: Double, reps: Int)?
    let unit: WeightUnit
    let onComplete: () -> Void
    let onWeightChange: (Double) -> Void
    let onRepsChange: (Int) -> Void

    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Set Number
            Text("\(entry.number)")
                .font(.body)
                .bold()
                .frame(width: 40, alignment: .leading)

            // Previous Data
            if let previous = previousData {
                let displayWeight = UnitConverter.toDisplay(previous.weight, unit: unit)
                let roundedWeight = Int(displayWeight.rounded())
                let _ = print("DEBUG SetRowView #\(entry.number): previousData.weight=\(previous.weight) (storage), displayWeight=\(displayWeight), roundedWeight=\(roundedWeight), entry.weight=\(entry.weight)")
                Text("\(roundedWeight)\(unit.abbreviation) × \(previous.reps)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 90, alignment: .leading)
            } else {
                Text("—")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 90, alignment: .leading)
            }

            // Weight Input
            TextField("0", value: Binding(
                get: { entry.weight },
                set: { onWeightChange($0) }
            ), format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(width: 70)
                .focused($isWeightFocused)
                .disabled(entry.isCompleted)

            // Reps Input
            TextField("0", value: Binding(
                get: { entry.reps },
                set: { onRepsChange($0) }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .frame(width: 70)
                .focused($isRepsFocused)
                .disabled(entry.isCompleted)

            // Complete Button
            Button(action: onComplete) {
                Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(entry.isCompleted ? .green : .secondary)
            }
            .disabled(entry.weight == 0 || entry.reps == 0)
            .frame(width: 44)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .opacity(entry.isCompleted ? 0.6 : 1.0)
    }
}

#Preview {
    let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
    LogExerciseView(exercise: exercise)
        .modelContainer(for: [Exercise.self, SetLog.self, WorkoutLog.self, UserPreferences.self], inMemory: true)
}
