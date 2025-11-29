import Foundation
import SwiftData

@Model
final class Routine {
    @Attribute(.unique) var dayOfWeek: String // "Monday", "Tuesday", etc.
    
    @Relationship(deleteRule: .nullify)
    var exercises: [Exercise]
    
    init(dayOfWeek: String, exercises: [Exercise] = []) {
        self.dayOfWeek = dayOfWeek
        self.exercises = exercises
    }
}
