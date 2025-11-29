import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var targetMuscleGroup: String
    
    // Inverse relationship (optional, but good for navigation)
    @Relationship(deleteRule: .cascade, inverse: \WorkoutLog.exercise)
    var logs: [WorkoutLog]?
    
    init(name: String, targetMuscleGroup: String) {
        self.id = UUID()
        self.name = name
        self.targetMuscleGroup = targetMuscleGroup
        self.logs = []
    }
}
