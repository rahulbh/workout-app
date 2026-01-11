//
//  SetLog.swift
//  workout-app
//
//  Individual set tracking model for proper workout logging
//

import Foundation
import SwiftData

@Model
final class SetLog {
    var id: UUID
    var setNumber: Int
    var reps: Int
    var weight: Double  // Stored in pounds internally
    var notes: String?
    var date: Date

    // Relationship
    var exercise: Exercise?

    // Computed property for volume
    var calculatedVolume: Double {
        return Double(reps) * weight
    }

    init(setNumber: Int, reps: Int, weight: Double, notes: String? = nil, date: Date = Date(), exercise: Exercise? = nil) {
        self.id = UUID()
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.notes = notes
        self.date = date
        self.exercise = exercise
    }
}
