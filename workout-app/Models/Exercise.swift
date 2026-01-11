import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var targetMuscleGroup: String

    // Exercise instructions and form cues
    var instructions: String?
    var formCues: String?
    var videoURL: String?

    // Inverse relationship (optional, but good for navigation)
    @Relationship(deleteRule: .cascade, inverse: \WorkoutLog.exercise)
    var logs: [WorkoutLog]?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.exercise)
    var setLogs: [SetLog]?

    init(
        name: String,
        targetMuscleGroup: String,
        instructions: String? = nil,
        formCues: String? = nil,
        videoURL: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.targetMuscleGroup = targetMuscleGroup
        self.instructions = instructions
        self.formCues = formCues
        self.videoURL = videoURL
        self.logs = []
        self.setLogs = []
    }
}
