//
//  RoutineView.swift
//  workout-app
//
//  Displays routine for a specific day with Start Routine functionality
//

import SwiftUI
import SwiftData

struct RoutineView: View {
    let day: String
    @Query var routines: [Routine]
    @Query private var allSetLogs: [SetLog]
    @Query private var preferences: [UserPreferences]

    @State private var showRoutineSession = false

    init(day: String) {
        self.day = day
        _routines = Query(filter: #Predicate<Routine> { $0.dayOfWeek == day })
    }

    private var userPreferences: UserPreferences {
        preferences.first ?? UserPreferences()
    }

    // Calculate today's volume for exercises in this routine
    private var todayVolume: Double {
        let calendar = Calendar.current
        let today = Date()

        guard let routine = routines.first else { return 0 }
        let routineExerciseIds = Set(routine.exercises.map { $0.id })

        return allSetLogs
            .filter { log in
                calendar.isDate(log.date, inSameDayAs: today) &&
                routineExerciseIds.contains(log.exercise?.id ?? UUID())
            }
            .reduce(0) { $0 + $1.calculatedVolume }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Today's volume header (if any logged)
            if todayVolume > 0 {
                TodayVolumeHeader(volume: todayVolume, unit: userPreferences.preferredWeightUnit)
                    .padding(.horizontal)
            }

            if let routine = routines.first, !routine.exercises.isEmpty {
                // Routine summary card with Start button
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(routine.exercises.count) exercises")
                                .font(.headline)

                            // Exercise names preview
                            Text(routine.exercises.prefix(3).map { $0.name }.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)

                            if routine.exercises.count > 3 {
                                Text("+ \(routine.exercises.count - 3) more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }

                    Button {
                        showRoutineSession = true
                    } label: {
                        Label("Start Routine", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                .padding(.horizontal)

                Spacer()
            } else {
                Spacer()
                ContentUnavailableView {
                    Label("No Routine", systemImage: "dumbbell")
                } description: {
                    Text("No exercises assigned for \(day).\nTap Edit to add exercises.")
                }
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showRoutineSession) {
            if let routine = routines.first {
                RoutineSessionView(routine: routine)
            }
        }
    }
}

#Preview {
    RoutineView(day: "Monday")
        .modelContainer(for: [Routine.self, Exercise.self, SetLog.self, UserPreferences.self], inMemory: true)
}
