import SwiftUI
import SwiftData
import Charts

struct MetricsView: View {
    @State private var selectedMuscleGroup: String = "All"
    @Query(sort: \WorkoutLog.date) var logs: [WorkoutLog]
    @Query private var preferences: [UserPreferences]

    private var userPreferences: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var muscleGroups: [String] {
        let groups = Set(logs.compactMap { $0.exercise?.targetMuscleGroup })
        return ["All"] + groups.sorted()
    }
    
    var filteredLogs: [WorkoutLog] {
        if selectedMuscleGroup == "All" {
            return logs
        } else {
            return logs.filter { $0.exercise?.targetMuscleGroup == selectedMuscleGroup }
        }
    }
    
    // Group logs by week and calculate total volume
    var weeklyVolume: [(week: Date, volume: Double)] {
        let calendar = Calendar.current
        let groupedByWeek = Dictionary(grouping: filteredLogs) { log in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: log.date)
        }
        
        return groupedByWeek.map { (key, value) in
            let date = calendar.date(from: key) ?? Date()
            let totalVolume = value.reduce(0) { $0 + $1.calculatedVolume }
            return (week: date, volume: totalVolume)
        }.sorted { $0.week < $1.week }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Muscle Group", selection: $selectedMuscleGroup) {
                    ForEach(muscleGroups, id: \.self) { group in
                        Text(group).tag(group)
                    }
                }
                .pickerStyle(.menu) // Segmented might be too crowded if many groups
                .padding()
                
                if weeklyVolume.isEmpty {
                    ContentUnavailableView("No Data", systemImage: "chart.xyaxis.line", description: Text("Log some workouts to see your progress."))
                } else {
                    VStack(alignment: .leading) {
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
                        .frame(height: 300)
                        .padding()
                    }
                    
                    List {
                        Section(header: Text("History")) {
                            ForEach(filteredLogs.reversed()) { log in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(log.exercise?.name ?? "Unknown")
                                            .font(.headline)
                                        Text(log.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        let displayVolume = UnitConverter.toDisplay(log.calculatedVolume, unit: userPreferences.preferredWeightUnit)
                                        let displayWeight = UnitConverter.toDisplay(log.weight, unit: userPreferences.preferredWeightUnit)
                                        Text("\(Int(displayVolume)) \(userPreferences.preferredWeightUnit.abbreviation)")
                                            .bold()
                                        Text("\(log.sets) x \(log.reps) @ \(Int(displayWeight))")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Metrics")
        }
    }
}

#Preview {
    MetricsView()
        .modelContainer(SampleData.shared.modelContainer)
}
