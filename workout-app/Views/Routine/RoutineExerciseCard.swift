//
//  RoutineExerciseCard.swift
//  workout-app
//
//  Expandable exercise card for routine session logging
//

import SwiftUI

struct RoutineExerciseCard: View {
    let exercise: Exercise
    @Binding var setEntries: [SessionSetEntry]
    let unit: WeightUnit
    let previousSets: [Int: (weight: Double, reps: Int)]
    var onSetCompleted: (() -> Void)? = nil

    @State private var isExpanded = false

    private var completedSetsCount: Int {
        setEntries.filter { $0.isCompleted }.count
    }

    private var exerciseVolume: Double {
        setEntries
            .filter { $0.isCompleted }
            .reduce(0) { $0 + Double($1.reps) * $1.weight }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        HStack(spacing: 8) {
                            Text(exercise.targetMuscleGroup)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if completedSetsCount > 0 {
                                Text("\(completedSetsCount) sets done")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    Spacer()

                    // Volume indicator if any completed
                    if exerciseVolume > 0 {
                        let displayVolume = UnitConverter.toDisplay(exerciseVolume, unit: unit)
                        Text("\(Int(displayVolume)) \(unit.abbreviation)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(completedSetsCount > 0 ? Color.green.opacity(0.1) : Color(.systemBackground))
            }
            .buttonStyle(.plain)

            // Expandable content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()

                    // Form cues (if available)
                    if let formCues = exercise.formCues, !formCues.isEmpty {
                        DisclosureGroup("Form Cues") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(formCues.components(separatedBy: "\n"), id: \.self) { cue in
                                    if !cue.trimmingCharacters(in: .whitespaces).isEmpty {
                                        HStack(alignment: .top, spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                                .font(.caption2)
                                            Text(cue)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        Divider()
                    }

                    // Set header
                    HStack(spacing: 8) {
                        Text("SET")
                            .frame(width: 35, alignment: .leading)
                        Text("PREVIOUS")
                            .frame(width: 80, alignment: .leading)
                        Text(unit.abbreviation.uppercased())
                            .frame(width: 60, alignment: .center)
                        Text("REPS")
                            .frame(width: 50, alignment: .center)
                        Spacer()
                            .frame(width: 40)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))

                    // Set rows
                    ForEach(Array(setEntries.enumerated()), id: \.element.id) { index, entry in
                        SessionSetRow(
                            entry: $setEntries[index],
                            setNumber: index + 1,
                            previousData: previousSets[index + 1],
                            unit: unit,
                            onCompleted: onSetCompleted
                        )
                        if index < setEntries.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }

                    // Add set button
                    Button {
                        let newSet = SessionSetEntry()
                        setEntries.append(newSet)
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Set")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Session Set Entry Model
struct SessionSetEntry: Identifiable {
    let id = UUID()
    var weight: Double = 0
    var reps: Int = 0
    var isCompleted: Bool = false
}

// MARK: - Session Set Row
struct SessionSetRow: View {
    @Binding var entry: SessionSetEntry
    let setNumber: Int
    let previousData: (weight: Double, reps: Int)?
    let unit: WeightUnit
    var onCompleted: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            // Set number
            Text("\(setNumber)")
                .font(.subheadline)
                .bold()
                .frame(width: 35, alignment: .leading)

            // Previous data
            if let previous = previousData {
                let displayWeight = UnitConverter.toDisplay(previous.weight, unit: unit)
                Text("\(Int(displayWeight)) x \(previous.reps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .leading)
            } else {
                Text("-")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .leading)
            }

            // Weight input
            TextField("0", value: $entry.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .padding(6)
                .background(Color(.systemGray6))
                .cornerRadius(6)
                .frame(width: 60)
                .disabled(entry.isCompleted)

            // Reps input
            TextField("0", value: $entry.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .padding(6)
                .background(Color(.systemGray6))
                .cornerRadius(6)
                .frame(width: 50)
                .disabled(entry.isCompleted)

            // Complete button
            Button {
                let wasCompleted = entry.isCompleted
                entry.isCompleted.toggle()
                // Trigger timer only when marking as completed (not when uncompleting)
                if !wasCompleted && entry.isCompleted {
                    onCompleted?()
                }
            } label: {
                Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(entry.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .disabled(entry.weight == 0 || entry.reps == 0)
            .frame(width: 40)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .opacity(entry.isCompleted ? 0.6 : 1.0)
    }
}

#Preview {
    let exercise = Exercise(name: "Bench Press", targetMuscleGroup: "Chest")
    exercise.formCues = "Keep back flat\nLower to chest\nPush through heels"

    return RoutineExerciseCard(
        exercise: exercise,
        setEntries: .constant([
            SessionSetEntry(weight: 135, reps: 10, isCompleted: true),
            SessionSetEntry(weight: 135, reps: 8, isCompleted: false),
            SessionSetEntry()
        ]),
        unit: .pounds,
        previousSets: [1: (135, 10), 2: (135, 8), 3: (135, 6)]
    )
    .padding()
}
