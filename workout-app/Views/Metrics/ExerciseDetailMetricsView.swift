//
//  ExerciseDetailMetricsView.swift
//  workout-app
//
//  Detailed metrics view for a single exercise with charts
//

import SwiftUI
import SwiftData
import Charts

struct ExerciseDetailMetricsView: View {
    let exercise: Exercise

    @Query private var allSetLogs: [SetLog]
    @Query private var preferences: [UserPreferences]

    private var userPreferences: UserPreferences {
        preferences.first ?? UserPreferences()
    }

    // Filter set logs for this exercise
    private var exerciseSetLogs: [SetLog] {
        allSetLogs
            .filter { $0.exercise?.id == exercise.id }
            .sorted { $0.date < $1.date }
    }

    // Group sets by workout session (same day)
    private var workoutSessions: [(date: Date, sets: [SetLog])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: exerciseSetLogs) { log in
            calendar.startOfDay(for: log.date)
        }
        return grouped.map { (date: $0.key, sets: $0.value.sorted { $0.setNumber < $1.setNumber }) }
            .sorted { $0.date < $1.date }
    }

    // Volume over time data
    private var volumeOverTime: [(date: Date, value: Double)] {
        workoutSessions.map { session in
            let totalVolume = session.sets.reduce(0) { $0 + $1.calculatedVolume }
            return (date: session.date, value: totalVolume)
        }
    }

    // Max weight over time (1RM approximation using heaviest set)
    private var maxWeightOverTime: [(date: Date, value: Double)] {
        workoutSessions.compactMap { session in
            guard let maxWeight = session.sets.max(by: { $0.weight < $1.weight })?.weight else {
                return nil
            }
            return (date: session.date, value: maxWeight)
        }
    }

    // Total reps over time
    private var totalRepsOverTime: [(date: Date, reps: Int)] {
        workoutSessions.map { session in
            let totalReps = session.sets.reduce(0) { $0 + $1.reps }
            return (date: session.date, reps: totalReps)
        }
    }

    // Summary statistics
    private var totalWorkouts: Int {
        workoutSessions.count
    }

    private var totalSets: Int {
        exerciseSetLogs.count
    }

    private var totalVolume: Double {
        exerciseSetLogs.reduce(0) { $0 + $1.calculatedVolume }
    }

    private var personalRecordWeight: Double? {
        exerciseSetLogs.max(by: { $0.weight < $1.weight })?.weight
    }

    private var personalRecordVolume: Double? {
        volumeOverTime.max(by: { $0.value < $1.value })?.value
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Stats
                summarySection

                if exerciseSetLogs.isEmpty {
                    ContentUnavailableView(
                        "No Data Yet",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Log some sets for \(exercise.name) to see your progress.")
                    )
                    .padding(.top, 40)
                } else {
                    // Volume Chart
                    chartSection(
                        title: "Volume Over Time",
                        data: volumeOverTime,
                        valueLabel: "Volume",
                        color: .blue,
                        formatter: { value in
                            let displayValue = UnitConverter.toDisplay(value, unit: userPreferences.preferredWeightUnit)
                            return "\(Int(displayValue)) \(userPreferences.preferredWeightUnit.abbreviation)"
                        }
                    )

                    // Max Weight Chart
                    chartSection(
                        title: "Max Weight Over Time",
                        data: maxWeightOverTime,
                        valueLabel: "Weight",
                        color: .green,
                        formatter: { value in
                            let displayValue = UnitConverter.toDisplay(value, unit: userPreferences.preferredWeightUnit)
                            return "\(Int(displayValue)) \(userPreferences.preferredWeightUnit.abbreviation)"
                        }
                    )

                    // Total Reps Chart
                    repsChartSection

                    // Recent History
                    recentHistorySection
                }
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Workouts",
                    value: "\(totalWorkouts)",
                    icon: "figure.strengthtraining.traditional"
                )

                StatCard(
                    title: "Total Sets",
                    value: "\(totalSets)",
                    icon: "list.number"
                )
            }

            HStack(spacing: 16) {
                if let prWeight = personalRecordWeight {
                    let displayWeight = UnitConverter.toDisplay(prWeight, unit: userPreferences.preferredWeightUnit)
                    StatCard(
                        title: "PR Weight",
                        value: "\(Int(displayWeight)) \(userPreferences.preferredWeightUnit.abbreviation)",
                        icon: "trophy.fill",
                        accentColor: .yellow
                    )
                }

                if let prVolume = personalRecordVolume {
                    let displayVolume = UnitConverter.toDisplay(prVolume, unit: userPreferences.preferredWeightUnit)
                    StatCard(
                        title: "PR Volume",
                        value: "\(Int(displayVolume)) \(userPreferences.preferredWeightUnit.abbreviation)",
                        icon: "star.fill",
                        accentColor: .orange
                    )
                }
            }
        }
    }

    // MARK: - Chart Section

    private func chartSection(
        title: String,
        data: [(date: Date, value: Double)],
        valueLabel: String,
        color: Color,
        formatter: @escaping (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            if data.count < 2 {
                Text("Need at least 2 workouts to show chart")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(data, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value(valueLabel, item.value)
                        )
                        .foregroundStyle(color)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value(valueLabel, item.value)
                        )
                        .foregroundStyle(color)

                        AreaMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value(valueLabel, item.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(formatter(doubleValue))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Reps Chart Section

    private var repsChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Reps Over Time")
                .font(.headline)

            if totalRepsOverTime.count < 2 {
                Text("Need at least 2 workouts to show chart")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(totalRepsOverTime, id: \.date) { item in
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Reps", item.reps)
                        )
                        .foregroundStyle(.purple.gradient)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Recent History Section

    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent History")
                .font(.headline)

            ForEach(workoutSessions.suffix(5).reversed(), id: \.date) { session in
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(session.sets, id: \.id) { setLog in
                        let displayWeight = UnitConverter.toDisplay(setLog.weight, unit: userPreferences.preferredWeightUnit)
                        HStack {
                            Text("Set \(setLog.setNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(setLog.reps) reps @ \(Int(displayWeight)) \(userPreferences.preferredWeightUnit.abbreviation)")
                                .font(.caption)
                        }
                    }

                    let sessionVolume = session.sets.reduce(0) { $0 + $1.calculatedVolume }
                    let displayVolume = UnitConverter.toDisplay(sessionVolume, unit: userPreferences.preferredWeightUnit)
                    Text("Total: \(Int(displayVolume)) \(userPreferences.preferredWeightUnit.abbreviation)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var accentColor: Color = .blue

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(accentColor)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailMetricsView(exercise: Exercise(name: "Bench Press", targetMuscleGroup: "Chest"))
    }
    .modelContainer(SampleData.shared.modelContainer)
}
