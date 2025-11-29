import Foundation
import SwiftData

@Model
final class WorkoutLog {
    var id: UUID
    var date: Date
    var sets: Int
    var reps: Int
    var weight: Double
    var calculatedVolume: Double
    
    var exercise: Exercise?
    
    init(date: Date, sets: Int, reps: Int, weight: Double, exercise: Exercise) {
        self.id = UUID()
        self.date = date
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.exercise = exercise
        self.calculatedVolume = Double(sets * reps) * weight
    }
}
