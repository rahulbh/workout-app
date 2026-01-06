//
//  UnitConverter.swift
//  workout-app
//
//  Created by Claude Code
//

import Foundation

struct UnitConverter {
    // Conversion constants
    private static let poundsToKgRatio = 0.45359237
    private static let kgToPoundsRatio = 2.20462262

    // MARK: - Basic Conversions

    /// Convert kilograms to pounds
    static func kgToLbs(_ kg: Double) -> Double {
        return kg * kgToPoundsRatio
    }

    /// Convert pounds to kilograms
    static func lbsToKg(_ lbs: Double) -> Double {
        return lbs * poundsToKgRatio
    }

    // MARK: - Unit-Based Conversions

    /// Convert weight from one unit to another
    static func convert(_ weight: Double, from: WeightUnit, to: WeightUnit) -> Double {
        if from == to {
            return weight
        }

        switch (from, to) {
        case (.pounds, .kilograms):
            return lbsToKg(weight)
        case (.kilograms, .pounds):
            return kgToLbs(weight)
        default:
            return weight
        }
    }

    /// Convert weight from storage format (pounds) to display format based on user preference
    static func toDisplay(_ weightInPounds: Double, unit: WeightUnit) -> Double {
        return convert(weightInPounds, from: .pounds, to: unit)
    }

    /// Convert weight from user input to storage format (pounds)
    static func toStorage(_ weight: Double, from unit: WeightUnit) -> Double {
        return convert(weight, from: unit, to: .pounds)
    }

    // MARK: - Display Formatting

    /// Format weight for display with appropriate unit label
    static func displayWeight(_ weight: Double, in unit: WeightUnit, decimals: Int = 1) -> String {
        let converted = toDisplay(weight, unit: unit)
        return String(format: "%.\(decimals)f %@", converted, unit.abbreviation)
    }

    /// Format weight value only (no unit label)
    static func displayValue(_ weight: Double, in unit: WeightUnit, decimals: Int = 1) -> String {
        let converted = toDisplay(weight, unit: unit)
        return String(format: "%.\(decimals)f", converted)
    }

    /// Format weight for detailed display
    static func detailedDisplay(_ weight: Double, in unit: WeightUnit) -> String {
        let converted = toDisplay(weight, unit: unit)
        return String(format: "%.2f %@", converted, unit.displayName)
    }
}
