//
//  SessionVolumeHeader.swift
//  workout-app
//
//  Reusable header component showing workout volume
//

import SwiftUI

struct SessionVolumeHeader: View {
    let volume: Double
    let unit: WeightUnit
    var label: String = "Session Volume"

    private var displayVolume: Double {
        UnitConverter.toDisplay(volume, unit: unit)
    }

    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.title3)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(displayVolume)) \(unit.abbreviation)")
                .font(.title2)
                .bold()
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// Today's volume variant for RoutineView
struct TodayVolumeHeader: View {
    let volume: Double
    let unit: WeightUnit

    private var displayVolume: Double {
        UnitConverter.toDisplay(volume, unit: unit)
    }

    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)

            Text("Today's Volume:")
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(displayVolume)) \(unit.abbreviation)")
                .bold()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        SessionVolumeHeader(volume: 5000, unit: .pounds)
        TodayVolumeHeader(volume: 3500, unit: .kilograms)
    }
    .padding()
}
