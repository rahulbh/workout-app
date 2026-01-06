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
    @Query private var allLogs: [WorkoutLog]

    @State private var setEntries: [SetEntry] = [SetEntry(number: 1)]
    @State private var notes: String = ""

    private var userPreferences: UserPreferences {
        preferences.first ?? UserPreferences()
    }

    // Get previous workout data for this exercise
    private var previousSets: [Int: (weight: Double, reps: Int)] {
        let exerciseLogs = allLogs
            .filter { $0.exercise?.id == exercise.id }
            .sorted { $0.date > $1.date }

        guard let lastWorkout = exerciseLogs.first else { return [:] }

        // For now, return the last workout's data for each set
        // In Phase 2, we'll track individual sets properly
        var result: [Int: (weight: Double, reps: Int)] = [:]
        for i in 1...lastWorkout.sets {
            result[i] = (weight: lastWorkout.weight, reps: lastWorkout.reps)
        }
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
                            previousData: previousSets[entry.number],
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
            setEntries[index].isCompleted.toggle()
        }
    }

    private func finishWorkout() {
        let completedSets = setEntries.filter { $0.isCompleted }
        guard !completedSets.isEmpty else { return }

        // For now, log each set as a separate WorkoutLog
        // In Phase 2, we'll use the SetLog model
        for entry in completedSets {
            let weightInPounds = UnitConverter.toStorage(entry.weight, from: userPreferences.preferredWeightUnit)
            let log = WorkoutLog(
                date: Date(),
                sets: 1,
                reps: entry.reps,
                weight: weightInPounds,
                exercise: exercise
            )
            modelContext.insert(log)
        }

        dismiss()
    }
}

// MARK: - Set Entry Model
struct SetEntry: Identifiable {
    let id = UUID()
    let number: Int
    var weight: Double = 0
    var reps: Int = 0
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
                Text("\(Int(displayWeight))\(unit.abbreviation) × \(previous.reps)")
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
        .modelContainer(for: [Exercise.self, WorkoutLog.self, UserPreferences.self], inMemory: true)
}
