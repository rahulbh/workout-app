import SwiftUI
import SwiftData

@MainActor
class SampleData {
    static let shared = SampleData()
    
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            Exercise.self,
            WorkoutLog.self,
            Routine.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            insertSampleData()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    func insertSampleData() {
        let context = modelContainer.mainContext
        
        // Create Exercises
        let benchPress = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
        let squat = Exercise(name: "Squat", targetMuscleGroup: "Legs")
        let deadlift = Exercise(name: "Deadlift", targetMuscleGroup: "Back")
        
        context.insert(benchPress)
        context.insert(squat)
        context.insert(deadlift)
        
        // Create Routine
        let mondayRoutine = Routine(dayOfWeek: "Monday", exercises: [benchPress, squat])
        context.insert(mondayRoutine)
        
        // Create Logs
        let log1 = WorkoutLog(date: Date().addingTimeInterval(-86400 * 7), sets: 3, reps: 10, weight: 135, exercise: benchPress)
        let log2 = WorkoutLog(date: Date(), sets: 3, reps: 10, weight: 145, exercise: benchPress)
        
        context.insert(log1)
        context.insert(log2)
    }
}
