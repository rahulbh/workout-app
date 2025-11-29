import SwiftUI
import SwiftData

struct RoutineView: View {
    let day: String
    @Query var routines: [Routine]
    
    init(day: String) {
        self.day = day
        // Predicate to find routine for the specific day
        _routines = Query(filter: #Predicate<Routine> { $0.dayOfWeek == day })
    }
    
    var body: some View {
        VStack {
            if let routine = routines.first, !routine.exercises.isEmpty {
                List {
                    ForEach(routine.exercises) { exercise in
                        ExerciseRowView(exercise: exercise)
                    }
                }
                .listStyle(.plain)
            } else {
                ContentUnavailableView {
                    Label("No Routine", systemImage: "dumbbell")
                } description: {
                    Text("No exercises assigned for \(day).")
                } actions: {
                    // Button to edit routine could go here
                }
            }
        }
    }
}
