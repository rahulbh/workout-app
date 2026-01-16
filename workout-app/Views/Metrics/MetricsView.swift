import SwiftUI
import SwiftData
import Charts

struct MetricsView: View {
    @State private var selectedMuscleGroup: String = "All"
    @Query(sort: \SetLog.date) private var setLogs: [SetLog]
    @Query private var exercises: [Exercise]
    @Query private var preferences: [UserPreferences]

    private var userPreferences: UserPreferences {
        preferences.first ?? UserPreferences()
    }

    var muscleGroups: [String] {
        let groups = Set(setLogs.compactMap { $0.exercise?.targetMuscleGroup })
        return ["All"] + groups.sorted()
    }

    var filteredSetLogs: [SetLog] {
        if selectedMuscleGroup == "All" {
            return setLogs
        } else {
            return setLogs.filter { $0.exercise?.targetMuscleGroup == selectedMuscleGroup }
        }
    }

    // Group logs by week and calculate total volume
    var weeklyVolume: [(week: Date, volume: Double)] {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: filteredSetLogs) { log in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: log.date)
        }

        return groupedByWeek.map { (key, value) in
            let date = calendar.date(from: key) ?? Date()
            let totalVolume = value.reduce(0) { $0 + $1.calculatedVolume }
            return (week: date, volume: totalVolume)
        }.sorted { $0.week < $1.week }
    }

    // Exercises that have logs (for exercise list)
    var exercisesWithLogs: [Exercise] {
        let exerciseIds = Set(setLogs.compactMap { $0.exercise?.id })
        return exercises.filter { exerciseIds.contains($0.id) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Quick links section
                    quickLinksSection

                    // Muscle group filter
                    Picker("Muscle Group", selection: $selectedMuscleGroup) {
                        ForEach(muscleGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)

                    if weeklyVolume.isEmpty {
                        ContentUnavailableView("No Data", systemImage: "chart.xyaxis.line", description: Text("Log some workouts to see your progress."))
                            .padding(.top, 40)
                    } else {
                        // Volume chart
                        volumeChartSection

                        // Exercise list
                        exerciseListSection
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Metrics")
        }
    }

    // MARK: - Quick Links Section

    private var quickLinksSection: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: WorkoutCalendarView()) {
                QuickLinkCard(
                    title: "Calendar",
                    icon: "calendar",
                    color: .blue
                )
            }

            NavigationLink(destination: MuscleGroupBreakdownView()) {
                QuickLinkCard(
                    title: "Muscle Groups",
                    icon: "chart.pie.fill",
                    color: .green
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Volume Chart Section

    private var volumeChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Volume Over Time")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(weeklyVolume, id: \.week) { item in
                    LineMark(
                        x: .value("Week", item.week, unit: .weekOfYear),
                        y: .value("Volume", item.volume)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)

                    AreaMark(
                        x: .value("Week", item.week, unit: .weekOfYear),
                        y: .value("Volume", item.volume)
                    )
                    .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Exercise List Section

    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline)
                .padding(.horizontal)

            ForEach(exercisesWithLogs) { exercise in
                NavigationLink(destination: ExerciseDetailMetricsView(exercise: exercise)) {
                    ExerciseMetricRow(
                        exercise: exercise,
                        setLogs: setLogs.filter { $0.exercise?.id == exercise.id },
                        unit: userPreferences.preferredWeightUnit
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Quick Link Card

struct QuickLinkCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Exercise Metric Row

struct ExerciseMetricRow: View {
    let exercise: Exercise
    let setLogs: [SetLog]
    let unit: WeightUnit

    private var totalVolume: Double {
        setLogs.reduce(0) { $0 + $1.calculatedVolume }
    }

    private var workoutCount: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(setLogs.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    private var maxWeight: Double {
        setLogs.max(by: { $0.weight < $1.weight })?.weight ?? 0
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(exercise.targetMuscleGroup)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                let displayMax = UnitConverter.toDisplay(maxWeight, unit: unit)
                Text("Max: \(Int(displayMax)) \(unit.abbreviation)")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text("\(workoutCount) workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    MetricsView()
        .modelContainer(SampleData.shared.modelContainer)
}
