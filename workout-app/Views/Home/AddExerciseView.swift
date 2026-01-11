import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var name = ""
    @State private var muscleGroup = "Chest"
    @State private var instructions = ""
    @State private var formCues = ""
    @State private var videoURL = ""
    @State private var showAdvanced = false

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

                Section {
                    Toggle("Add Instructions", isOn: $showAdvanced.animation())
                }

                if showAdvanced {
                    Section {
                        TextEditor(text: $instructions)
                            .frame(minHeight: 80)
                    } header: {
                        Text("Instructions")
                    } footer: {
                        Text("Step-by-step instructions for the exercise.")
                    }

                    Section {
                        TextEditor(text: $formCues)
                            .frame(minHeight: 80)
                    } header: {
                        Text("Form Cues")
                    } footer: {
                        Text("Key form reminders. Put each cue on a new line.")
                    }

                    Section {
                        TextField("https://...", text: $videoURL)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .autocapitalization(.none)
                    } header: {
                        Text("Video URL")
                    } footer: {
                        Text("Optional link to a tutorial video.")
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
        let exercise = Exercise(
            name: name,
            targetMuscleGroup: muscleGroup,
            instructions: instructions.isEmpty ? nil : instructions,
            formCues: formCues.isEmpty ? nil : formCues,
            videoURL: videoURL.isEmpty ? nil : videoURL
        )
        modelContext.insert(exercise)
        dismiss()
    }
}
