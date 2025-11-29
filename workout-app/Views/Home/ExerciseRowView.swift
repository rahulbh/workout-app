import SwiftUI

struct ExerciseRowView: View {
    let exercise: Exercise
    @State private var showingLogSheet = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.headline)
                Text(exercise.targetMuscleGroup)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {
                showingLogSheet = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingLogSheet) {
            LogExerciseView(exercise: exercise)
        }
    }
}
