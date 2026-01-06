import SwiftUI
import SwiftData

struct EditRoutineView: View {
    let day: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: \Exercise.name) var allExercises: [Exercise]
    @Query var routines: [Routine]

    @State private var showingAddExercise = false
    @State private var searchText = ""
    
    var currentRoutine: Routine? {
        routines.first(where: { $0.dayOfWeek == day })
    }

    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return allExercises
        }
        return allExercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText) ||
            exercise.targetMuscleGroup.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Select Exercises for \(day)")) {
                    if allExercises.isEmpty {
                        Text("No exercises created yet. Tap + to add one.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredExercises) { exercise in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(exercise.name)
                                        .font(.body)
                                    Text(exercise.targetMuscleGroup)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if isExerciseInRoutine(exercise) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleExercise(exercise)
                            }
                        }
                        .onDelete(perform: deleteExercise)
                    }
                }
            }
            .navigationTitle("Edit Routine")
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddExercise = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView()
            }
            .onAppear {
                ensureRoutineExists()
            }
        }
    }
    
    func ensureRoutineExists() {
        if currentRoutine == nil {
            let newRoutine = Routine(dayOfWeek: day)
            modelContext.insert(newRoutine)
        }
    }
    
    func isExerciseInRoutine(_ exercise: Exercise) -> Bool {
        currentRoutine?.exercises.contains(exercise) ?? false
    }
    
    func toggleExercise(_ exercise: Exercise) {
        guard let routine = currentRoutine else { return }
        
        if let index = routine.exercises.firstIndex(of: exercise) {
            routine.exercises.remove(at: index)
        } else {
            routine.exercises.append(exercise)
        }
    }
    
    func deleteExercise(at offsets: IndexSet) {
        for index in offsets {
            let exercise = allExercises[index]
            modelContext.delete(exercise)
        }
    }
}
