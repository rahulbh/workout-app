import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var name = ""
    @State private var muscleGroup = "Chest"
    let muscleGroups = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Core", "Cardio"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Exercise Name", text: $name)
                    
                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(muscleGroups, id: \.self) { group in
                            Text(group)
                        }
                    }
                }
            }
            .navigationTitle("New Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExercise()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    func saveExercise() {
        let exercise = Exercise(name: name, targetMuscleGroup: muscleGroup)
        modelContext.insert(exercise)
        dismiss()
    }
}
