//
//  RoutineSessionView.swift
//  workout-app
//
//  Full routine logging session - shows all exercises for the day
//

import SwiftUI
import SwiftData

struct RoutineSessionView: View {
    let routine: Routine
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query private var preferences: [UserPreferences]
    @Query private var allSetLogs: [SetLog]

    @State private var sessionStartTime = Date()
    @State private var exerciseSetEntries: [UUID: [SessionSetEntry]] = [:]
    @State private var showFinishConfirmation = false
    @State private var isSaving = false
    @State private var showRestTimer = false
    @State private var skipTimerForSession = false

    private var userPreferences: UserPreferences {
        preferences.first ?? UserPreferences()
    }

    // Computed session volume from all completed sets
    private var sessionVolume: Double {
        exerciseSetEntries.values.flatMap { $0 }
            .filter { $0.isCompleted }
            .reduce(0) { $0 + Double($1.reps) * $1.weight }
    }

    private var completedSetsCount: Int {
        exerciseSetEntries.values.flatMap { $0 }
            .filter { $0.isCompleted }
            .count
    }

    private var hasCompletedSets: Bool {
        completedSetsCount > 0
    }

    // Get previous sets for an exercise (most recent workout)
    private func previousSets(for exercise: Exercise) -> [Int: (weight: Double, reps: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get all SetLogs for this exercise before today
        let exerciseLogs = allSetLogs
            .filter { log in
                log.exercise?.id == exercise.id &&
                calendar.startOfDay(for: log.date) < today
            }
            .sorted { $0.date > $1.date }

        // Get the most recent workout date
        guard let mostRecentDate = exerciseLogs.first?.date else {
            return [:]
        }

        // Get all sets from that date
        let mostRecentSets = exerciseLogs.filter {
            calendar.isDate($0.date, inSameDayAs: mostRecentDate)
        }

        // Map set number to weight/reps
        var result: [Int: (weight: Double, reps: Int)] = [:]
        for log in mostRecentSets {
            result[log.setNumber] = (log.weight, log.reps)
        }

        return result
    }

    // Initialize set entries from previous workout
    private func initializeSetEntries() {
        for exercise in routine.exercises {
            let previous = previousSets(for: exercise)
            if previous.isEmpty {
                // Default to 3 empty sets
                exerciseSetEntries[exercise.id] = [
                    SessionSetEntry(),
                    SessionSetEntry(),
                    SessionSetEntry()
                ]
            } else {
                // Create sets based on previous workout
                let maxSetNumber = previous.keys.max() ?? 3
                var entries: [SessionSetEntry] = []
                for setNum in 1...maxSetNumber {
                    if let prev = previous[setNum] {
                        entries.append(SessionSetEntry(weight: prev.weight, reps: prev.reps))
                    } else {
                        entries.append(SessionSetEntry())
                    }
                }
                exerciseSetEntries[exercise.id] = entries
            }
        }
    }

    private func binding(for exerciseId: UUID) -> Binding<[SessionSetEntry]> {
        Binding(
            get: { exerciseSetEntries[exerciseId] ?? [] },
            set: { exerciseSetEntries[exerciseId] = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Session volume header
                    SessionVolumeHeader(volume: sessionVolume, unit: userPreferences.preferredWeightUnit)

                    // Skip timer toggle (if timer is enabled)
                    if userPreferences.enableRestTimer {
                        HStack {
                            Toggle("Skip rest timer", isOn: $skipTimerForSession)
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                    }

                    // Exercise list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(routine.exercises) { exercise in
                                RoutineExerciseCard(
                                    exercise: exercise,
                                    setEntries: binding(for: exercise.id),
                                    unit: userPreferences.preferredWeightUnit,
                                    previousSets: previousSets(for: exercise),
                                    onSetCompleted: {
                                        triggerRestTimer()
                                    }
                                )
                            }
                        }
                        .padding()
                        .padding(.bottom, showRestTimer ? 80 : 0)
                    }
                }

                // Inline rest timer at bottom
                if showRestTimer {
                    InlineRestTimerView(
                        duration: TimeInterval(userPreferences.defaultRestDuration),
                        onComplete: { showRestTimer = false },
                        onSkip: { showRestTimer = false }
                    )
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle(routine.dayOfWeek)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasCompletedSets {
                            showFinishConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Finish") {
                        Task {
                            await finishSession()
                        }
                    }
                    .bold()
                    .disabled(!hasCompletedSets || isSaving)
                }
            }
            .onAppear {
                if exerciseSetEntries.isEmpty {
                    initializeSetEntries()
                }
            }
            .confirmationDialog(
                "Discard Workout?",
                isPresented: $showFinishConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Logging", role: .cancel) {}
            } message: {
                Text("You have \(completedSetsCount) completed sets. Are you sure you want to discard this workout?")
            }
        }
    }

    private func triggerRestTimer() {
        if userPreferences.enableRestTimer && !skipTimerForSession {
            withAnimation {
                showRestTimer = true
            }
        }
    }

    private func finishSession() async {
        isSaving = true

        // Save all completed sets to SwiftData
        for exercise in routine.exercises {
            guard let entries = exerciseSetEntries[exercise.id] else { continue }

            for (index, entry) in entries.enumerated() where entry.isCompleted {
                let setLog = SetLog(
                    setNumber: index + 1,
                    reps: entry.reps,
                    weight: entry.weight,
                    date: Date(),
                    exercise: exercise
                )
                modelContext.insert(setLog)
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save sets: \(error)")
        }

        // Save to HealthKit if enabled
        if userPreferences.healthKitEnabled {
            let healthKit = HealthKitManager()
            await healthKit.requestAuthorization()

            if healthKit.isAuthorized {
                let endTime = Date()
                let durationMinutes = endTime.timeIntervalSince(sessionStartTime) / 60
                let calories = HealthKitManager.estimateCalories(durationMinutes: durationMinutes)

                do {
                    try await healthKit.saveWorkout(
                        start: sessionStartTime,
                        end: endTime,
                        calories: calories
                    )
                } catch {
                    print("Failed to save to HealthKit: \(error)")
                }
            }
        }

        isSaving = false
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Routine.self, Exercise.self, SetLog.self, UserPreferences.self, configurations: config)

    let exercise1 = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
    exercise1.formCues = "Keep back flat\nLower to chest\nPush through heels"
    let exercise2 = Exercise(name: "Incline Dumbbell Press", targetMuscleGroup: "Chest")
    let exercise3 = Exercise(name: "Cable Flyes", targetMuscleGroup: "Chest")

    let routine = Routine(dayOfWeek: "Monday")
    routine.exercises = [exercise1, exercise2, exercise3]

    container.mainContext.insert(exercise1)
    container.mainContext.insert(exercise2)
    container.mainContext.insert(exercise3)
    container.mainContext.insert(routine)

    return RoutineSessionView(routine: routine)
        .modelContainer(container)
}
