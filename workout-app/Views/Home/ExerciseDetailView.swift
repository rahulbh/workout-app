//
//  ExerciseDetailView.swift
//  workout-app
//
//  Full exercise detail screen with instructions and form cues
//

import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.largeTitle)
                        .bold()

                    Label(exercise.targetMuscleGroup, systemImage: "figure.strengthtraining.traditional")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                Divider()

                // Instructions Section
                if let instructions = exercise.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Instructions", systemImage: "list.bullet.clipboard")
                            .font(.headline)

                        Text(instructions)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Instructions", systemImage: "list.bullet.clipboard")
                            .font(.headline)

                        Text("No instructions available for this exercise.")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .italic()
                    }
                    .padding(.horizontal)
                }

                // Form Cues Section
                if let formCues = exercise.formCues, !formCues.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Form Cues", systemImage: "checkmark.circle")
                            .font(.headline)

                        ForEach(formCues.components(separatedBy: "\n"), id: \.self) { cue in
                            if !cue.trimmingCharacters(in: .whitespaces).isEmpty {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(.blue)
                                        .font(.caption)
                                        .padding(.top, 4)

                                    Text(cue)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Video Link Section
                if let videoURL = exercise.videoURL, !videoURL.isEmpty, let url = URL(string: videoURL) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Video Tutorial", systemImage: "play.circle")
                            .font(.headline)

                        Link(destination: url) {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.title2)
                                Text("Watch Tutorial")
                                    .font(.body)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditExerciseInstructionsView(exercise: exercise)
        }
    }
}

// MARK: - Edit Exercise Instructions View
struct EditExerciseInstructionsView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var instructions: String = ""
    @State private var formCues: String = ""
    @State private var videoURL: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise Name", text: .constant(exercise.name))
                        .disabled(true)
                        .foregroundStyle(.secondary)

                    Text(exercise.targetMuscleGroup)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Exercise")
                }

                Section {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                } header: {
                    Text("Instructions")
                } footer: {
                    Text("Step-by-step instructions for performing the exercise.")
                }

                Section {
                    TextEditor(text: $formCues)
                        .frame(minHeight: 100)
                } header: {
                    Text("Form Cues")
                } footer: {
                    Text("Key points to remember. Put each cue on a new line.")
                }

                Section {
                    TextField("https://...", text: $videoURL)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                } header: {
                    Text("Video URL")
                } footer: {
                    Text("Link to a video tutorial (YouTube, etc.)")
                }
            }
            .navigationTitle("Edit Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                instructions = exercise.instructions ?? ""
                formCues = exercise.formCues ?? ""
                videoURL = exercise.videoURL ?? ""
            }
        }
    }

    private func saveChanges() {
        exercise.instructions = instructions.isEmpty ? nil : instructions
        exercise.formCues = formCues.isEmpty ? nil : formCues
        exercise.videoURL = videoURL.isEmpty ? nil : videoURL
        try? modelContext.save()
    }
}

#Preview {
    let exercise = Exercise(
        name: "Bench Press",
        targetMuscleGroup: "Chest",
        instructions: "Lie on the bench with your feet flat on the floor. Grip the bar slightly wider than shoulder width. Unrack the bar and lower it to your chest. Press the bar back up to the starting position.",
        formCues: "Keep your shoulder blades pinched together\nDrive your feet into the ground\nKeep your wrists straight\nTouch the bar to your lower chest"
    )

    NavigationStack {
        ExerciseDetailView(exercise: exercise)
    }
    .modelContainer(for: [Exercise.self], inMemory: true)
}
