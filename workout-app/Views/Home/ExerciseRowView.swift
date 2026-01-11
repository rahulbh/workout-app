import SwiftUI

struct ExerciseRowView: View {
    let exercise: Exercise
    @State private var showingLogSheet = false
    @State private var showingDetailSheet = false

    var body: some View {
        HStack {
            // Tappable area for exercise details
            Button {
                showingDetailSheet = true
            } label: {
                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        // Info indicator if exercise has instructions
                        if exercise.instructions != nil || exercise.formCues != nil {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue.opacity(0.7))
                        }
                    }
                    Text(exercise.targetMuscleGroup)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

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
        .sheet(isPresented: $showingDetailSheet) {
            NavigationStack {
                ExerciseDetailView(exercise: exercise)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingDetailSheet = false
                            }
                        }
                    }
            }
        }
    }
}
