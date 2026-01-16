//
//  SettingsView.swift
//  workout-app
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    @State private var healthKitManager = HealthKitManager()

    private var userPreferences: UserPreferences {
        if let existing = preferences.first {
            return existing
        } else {
            let newPrefs = UserPreferences()
            modelContext.insert(newPrefs)
            return newPrefs
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Weight Unit", selection: Binding(
                        get: { userPreferences.preferredWeightUnit },
                        set: { newValue in
                            userPreferences.preferredWeightUnit = newValue
                            try? modelContext.save()
                        }
                    )) {
                        ForEach([WeightUnit.pounds, WeightUnit.kilograms], id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }

                    HStack {
                        Text("Current Setting")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(userPreferences.preferredWeightUnit.abbreviation)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Units")
                } footer: {
                    Text("All weights are stored in pounds internally and converted for display.")
                }

                Section {
                    Toggle("Enable Rest Timer", isOn: Binding(
                        get: { userPreferences.enableRestTimer },
                        set: { newValue in
                            userPreferences.enableRestTimer = newValue
                            try? modelContext.save()
                        }
                    ))

                    if userPreferences.enableRestTimer {
                        Stepper(value: Binding(
                            get: { userPreferences.defaultRestDuration },
                            set: { newValue in
                                userPreferences.defaultRestDuration = newValue
                                try? modelContext.save()
                            }
                        ), in: 30...300, step: 15) {
                            HStack {
                                Text("Default Rest Duration")
                                Spacer()
                                Text("\(userPreferences.defaultRestDuration)s")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Workout")
                } footer: {
                    Text("Rest timer will automatically start after logging a set.")
                }

                Section {
                    if HealthKitManager.isAvailable {
                        Toggle("Sync to Apple Health", isOn: Binding(
                            get: { userPreferences.healthKitEnabled },
                            set: { newValue in
                                userPreferences.healthKitEnabled = newValue
                                try? modelContext.save()
                                if newValue {
                                    Task {
                                        await healthKitManager.requestAuthorization()
                                    }
                                }
                            }
                        ))

                        if userPreferences.healthKitEnabled {
                            HStack {
                                Text("Status")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if healthKitManager.isAuthorized {
                                    Label("Connected", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.subheadline)
                                } else {
                                    Label("Not Connected", systemImage: "exclamationmark.circle")
                                        .foregroundStyle(.orange)
                                        .font(.subheadline)
                                }
                            }
                        }

                        if let error = healthKitManager.authorizationError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    } else {
                        Text("Apple Health is not available on this device")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Apple Health")
                } footer: {
                    if HealthKitManager.isAvailable {
                        Text("When enabled, completed workouts will be saved to Apple Health with duration and estimated calories.")
                    }
                }

                Section {
                    HStack {
                        Text("App Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserPreferences.self, Exercise.self, WorkoutLog.self, Routine.self], inMemory: true)
}
