//
//  MuscleGroupBreakdownView.swift
//  workout-app
//
//  Pie chart and breakdown of volume by muscle group
//

import SwiftUI
import SwiftData
import Charts

struct MuscleGroupBreakdownView: View {
    @Query(sort: \SetLog.date) private var allSetLogs: [SetLog]
    @Query private var preferences: [UserPreferences]

    @State private var selectedTimeRange: TimeRange = .allTime
    @State private var selectedMuscleGroup: String?

    private var userPreferences: UserPreferences {
        preferences.first ?? UserPreferences()
    }

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case allTime = "All Time"

        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .allTime: return nil
            }
        }
    }

    // Filter logs by time range
    private var filteredSetLogs: [SetLog] {
        guard let days = selectedTimeRange.days else {
            return allSetLogs
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return allSetLogs.filter { $0.date >= cutoffDate }
    }

    // Volume by muscle group
    private var muscleGroupVolume: [(group: String, volume: Double, color: Color)] {
        let grouped = Dictionary(grouping: filteredSetLogs) { log in
            log.exercise?.targetMuscleGroup ?? "Unknown"
        }

        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .teal, .yellow, .indigo, .mint]

        return grouped.map { (group, logs) in
            let volume = logs.reduce(0) { $0 + $1.calculatedVolume }
            return (group: group, volume: volume, color: Color.clear)
        }
        .sorted { $0.volume > $1.volume }
        .enumerated()
        .map { (index, item) in
            (group: item.group, volume: item.volume, color: colors[index % colors.count])
        }
    }

    private var totalVolume: Double {
        muscleGroupVolume.reduce(0) { $0 + $1.volume }
    }

    // Exercises for selected muscle group
    private var selectedGroupExercises: [(exercise: Exercise, volume: Double, setCount: Int)] {
        guard let selectedGroup = selectedMuscleGroup else { return [] }

        let groupLogs = filteredSetLogs.filter { $0.exercise?.targetMuscleGroup == selectedGroup }
        let byExercise = Dictionary(grouping: groupLogs) { $0.exercise }

        return byExercise.compactMap { (exercise, logs) in
            guard let exercise = exercise else { return nil }
            let volume = logs.reduce(0) { $0 + $1.calculatedVolume }
            return (exercise: exercise, volume: volume, setCount: logs.count)
        }
        .sorted { $0.volume > $1.volume }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time range picker
                timeRangePicker

                if muscleGroupVolume.isEmpty {
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "chart.pie",
                        description: Text("Log some workouts to see your muscle group breakdown.")
                    )
                    .padding(.top, 40)
                } else {
                    // Pie chart
                    pieChartSection

                    // Breakdown list
                    breakdownListSection

                    // Selected group details
                    if selectedMuscleGroup != nil {
                        selectedGroupSection
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Muscle Groups")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedTimeRange) { _, _ in
            selectedMuscleGroup = nil
        }
    }

    // MARK: - Pie Chart Section

    private var pieChartSection: some View {
        VStack(spacing: 12) {
            Text("Volume Distribution")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Chart(muscleGroupVolume, id: \.group) { item in
                    SectorMark(
                        angle: .value("Volume", item.volume),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color)
                    .opacity(selectedMuscleGroup == nil || selectedMuscleGroup == item.group ? 1.0 : 0.3)
                }
                .frame(height: 250)

                // Center text
                VStack {
                    let displayTotal = UnitConverter.toDisplay(totalVolume, unit: userPreferences.preferredWeightUnit)
                    Text("\(Int(displayTotal))")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(userPreferences.preferredWeightUnit.abbreviation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Breakdown List Section

    private var breakdownListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown")
                .font(.headline)

            ForEach(muscleGroupVolume, id: \.group) { item in
                MuscleGroupRow(
                    group: item.group,
                    volume: item.volume,
                    totalVolume: totalVolume,
                    color: item.color,
                    isSelected: selectedMuscleGroup == item.group,
                    unit: userPreferences.preferredWeightUnit
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if selectedMuscleGroup == item.group {
                            selectedMuscleGroup = nil
                        } else {
                            selectedMuscleGroup = item.group
                        }
                    }
                }
            }
        }
    }

    // MARK: - Selected Group Section

    private var selectedGroupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedMuscleGroup ?? "")
                    .font(.headline)

                Spacer()

                Button("Clear") {
                    withAnimation {
                        selectedMuscleGroup = nil
                    }
                }
                .font(.caption)
            }

            if selectedGroupExercises.isEmpty {
                Text("No exercises found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(selectedGroupExercises, id: \.exercise.id) { item in
                    ExerciseVolumeRow(
                        exercise: item.exercise,
                        volume: item.volume,
                        setCount: item.setCount,
                        unit: userPreferences.preferredWeightUnit
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Muscle Group Row

struct MuscleGroupRow: View {
    let group: String
    let volume: Double
    let totalVolume: Double
    let color: Color
    let isSelected: Bool
    let unit: WeightUnit

    private var percentage: Double {
        guard totalVolume > 0 else { return 0 }
        return (volume / totalVolume) * 100
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(group)
                .font(.subheadline)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                let displayVolume = UnitConverter.toDisplay(volume, unit: unit)
                Text("\(Int(displayVolume)) \(unit.abbreviation)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(isSelected ? color.opacity(0.15) : Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? color : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Exercise Volume Row

struct ExerciseVolumeRow: View {
    let exercise: Exercise
    let volume: Double
    let setCount: Int
    let unit: WeightUnit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline)

                Text("\(setCount) sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            let displayVolume = UnitConverter.toDisplay(volume, unit: unit)
            Text("\(Int(displayVolume)) \(unit.abbreviation)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        MuscleGroupBreakdownView()
    }
    .modelContainer(SampleData.shared.modelContainer)
}
