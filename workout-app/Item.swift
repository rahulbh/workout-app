//
//  Item.swift
//  workout-app
//
//  Created by Rahul Bharti on 28/11/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
