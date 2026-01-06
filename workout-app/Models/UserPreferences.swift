//
//  UserPreferences.swift
//  workout-app
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
final class UserPreferences {
    @Attribute(.unique) var id: String = "singleton"
    var preferredWeightUnit: WeightUnit
    var enableRestTimer: Bool
    var defaultRestDuration: Int

    init(
        preferredWeightUnit: WeightUnit = .pounds,
        enableRestTimer: Bool = true,
        defaultRestDuration: Int = 90
    ) {
        self.preferredWeightUnit = preferredWeightUnit
        self.enableRestTimer = enableRestTimer
        self.defaultRestDuration = defaultRestDuration
    }
}

enum WeightUnit: String, Codable {
    case pounds = "lbs"
    case kilograms = "kg"

    var displayName: String {
        switch self {
        case .pounds: return "Pounds (lbs)"
        case .kilograms: return "Kilograms (kg)"
        }
    }

    var abbreviation: String {
        return self.rawValue
    }
}
