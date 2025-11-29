import SwiftUI
import SwiftData

struct LogExerciseView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var weight: Double = 0.0
    @State private var reps: Int = 0
    @State private var sets: Int = 1
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Performance")) {
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("0", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Stepper(value: $reps, in: 0...100) {
                        HStack {
                            Text("Reps")
                            Spacer()
                            Text("\(reps)")
                        }
                    }
                    
                    Stepper(value: $sets, in: 1...20) {
                        HStack {
                            Text("Sets")
                            Spacer()
                            Text("\(sets)")
                        }
                    }
                }
                
                Section {
                    Button(action: logSet) {
                        Text("Log Set")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(reps == 0 || weight == 0)
                }
            }
            .navigationTitle("Log \(exercise.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func logSet() {
        let log = WorkoutLog(date: Date(), sets: sets, reps: reps, weight: weight, exercise: exercise)
        modelContext.insert(log)
        dismiss()
    }
}
