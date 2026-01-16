//
//  HealthKitManager.swift
//  workout-app
//
//  Manager for Apple Health integration - syncs workouts with HealthKit
//

import Foundation
import HealthKit

@MainActor
@Observable
class HealthKitManager {
    let healthStore = HKHealthStore()
    var isAuthorized = false
    var authorizationError: String?

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard HealthKitManager.isAvailable else {
            authorizationError = "HealthKit is not available on this device"
            return
        }

        let typesToShare: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType(.activeEnergyBurned)
        ]

        let typesToRead: Set<HKObjectType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType(.activeEnergyBurned)
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            checkAuthorizationStatus()
        } catch {
            authorizationError = "Authorization failed: \(error.localizedDescription)"
            isAuthorized = false
        }
    }

    func checkAuthorizationStatus() {
        let workoutType = HKWorkoutType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        isAuthorized = (status == .sharingAuthorized)
    }

    func saveWorkout(
        activityType: HKWorkoutActivityType = .traditionalStrengthTraining,
        start: Date,
        end: Date,
        calories: Double
    ) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        let workout = HKWorkout(
            activityType: activityType,
            start: start,
            end: end,
            duration: end.timeIntervalSince(start),
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
            totalDistance: nil,
            metadata: [
                HKMetadataKeyWorkoutBrandName: "Workout App"
            ]
        )

        try await healthStore.save(workout)
    }

    // Estimate calories burned during strength training
    // Based on average of ~7.5 calories per minute for moderate strength training
    static func estimateCalories(durationMinutes: Double) -> Double {
        return durationMinutes * 7.5
    }
}

enum HealthKitError: LocalizedError {
    case notAuthorized
    case notAvailable
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HealthKit authorization not granted"
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .saveFailed(let error):
            return "Failed to save workout: \(error.localizedDescription)"
        }
    }
}
