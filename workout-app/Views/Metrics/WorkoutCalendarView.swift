//
//  WorkoutCalendarView.swift
//  workout-app
//
//  Calendar view showing workout history with visual indicators
//

import SwiftUI
import SwiftData

struct WorkoutCalendarView: View {
    @Query(sort: \SetLog.date) private var allSetLogs: [SetLog]
    @Query private var preferences: [UserPreferences]

    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()

    private var userPreferences: UserPreferences {
        preferences.first ?? UserPreferences()
    }

    private let calendar = Calendar.current

    // Dates that have workouts
    private var workoutDates: Set<Date> {
        Set(allSetLogs.map { calendar.startOfDay(for: $0.date) })
    }

    // Get workout data for selected date
    private var selectedDateWorkouts: [Exercise: [SetLog]] {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let logsForDay = allSetLogs.filter { log in
            log.date >= startOfDay && log.date < endOfDay
        }

        return Dictionary(grouping: logsForDay) { $0.exercise ?? Exercise(name: "Unknown", targetMuscleGroup: "Unknown") }
    }

    // Calculate total volume for a date
    private func volumeForDate(_ date: Date) -> Double {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        return allSetLogs
            .filter { $0.date >= startOfDay && $0.date < endOfDay }
            .reduce(0) { $0 + $1.calculatedVolume }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Month navigation
            monthHeader

            // Day of week headers
            weekdayHeader

            // Calendar grid
            calendarGrid

            Divider()
                .padding(.top, 8)

            // Selected date details
            selectedDateDetails
        }
        .navigationTitle("Workout Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    CalendarDayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        hasWorkout: workoutDates.contains(calendar.startOfDay(for: date)),
                        volume: volumeForDate(date),
                        unit: userPreferences.preferredWeightUnit
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                } else {
                    Text("")
                        .frame(height: 44)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Selected Date Details

    private var selectedDateDetails: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(selectedDate, format: .dateTime.weekday(.wide).month().day())
                        .font(.headline)

                    Spacer()

                    let totalVolume = volumeForDate(selectedDate)
                    if totalVolume > 0 {
                        let displayVolume = UnitConverter.toDisplay(totalVolume, unit: userPreferences.preferredWeightUnit)
                        Text("\(Int(displayVolume)) \(userPreferences.preferredWeightUnit.abbreviation)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                if selectedDateWorkouts.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bed.double")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Rest Day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(Array(selectedDateWorkouts.keys).sorted { $0.name < $1.name }, id: \.id) { exercise in
                        if let sets = selectedDateWorkouts[exercise] {
                            WorkoutDaySummaryCard(
                                exercise: exercise,
                                sets: sets,
                                unit: userPreferences.preferredWeightUnit
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var currentDate = monthFirstWeek.start

        // Add days until we've passed the end of the month
        while currentDate < monthInterval.end || days.count % 7 != 0 {
            if currentDate >= monthInterval.start && currentDate < monthInterval.end {
                days.append(currentDate)
            } else {
                days.append(nil)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasWorkout: Bool
    let volume: Double
    let unit: WeightUnit

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(.body, design: .rounded))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(textColor)

            if hasWorkout {
                Circle()
                    .fill(workoutIndicatorColor)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private var textColor: Color {
        if isSelected {
            return .primary
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.15)
        } else if hasWorkout {
            return Color.green.opacity(0.1)
        } else {
            return Color.clear
        }
    }

    private var workoutIndicatorColor: Color {
        // Color intensity based on volume
        let displayVolume = UnitConverter.toDisplay(volume, unit: unit)
        if displayVolume > 10000 {
            return .green
        } else if displayVolume > 5000 {
            return .green.opacity(0.8)
        } else {
            return .green.opacity(0.6)
        }
    }
}

// MARK: - Workout Day Summary Card

struct WorkoutDaySummaryCard: View {
    let exercise: Exercise
    let sets: [SetLog]
    let unit: WeightUnit

    private var totalVolume: Double {
        sets.reduce(0) { $0 + $1.calculatedVolume }
    }

    private var maxWeight: Double {
        sets.max(by: { $0.weight < $1.weight })?.weight ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(exercise.targetMuscleGroup)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    let displayVolume = UnitConverter.toDisplay(totalVolume, unit: unit)
                    Text("\(Int(displayVolume)) \(unit.abbreviation)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    Text("\(sets.count) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Set details
            HStack(spacing: 8) {
                ForEach(sets.sorted { $0.setNumber < $1.setNumber }, id: \.id) { setLog in
                    let displayWeight = UnitConverter.toDisplay(setLog.weight, unit: unit)
                    Text("\(setLog.reps)×\(Int(displayWeight))")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        WorkoutCalendarView()
    }
    .modelContainer(SampleData.shared.modelContainer)
}
