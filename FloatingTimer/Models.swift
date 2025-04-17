//
//  Models.swift
//  FloatingTimer
//
//  Created by Ashutosh on 17/04/25.
//

import Foundation

struct SavedTimer: Codable, Identifiable {
    var id: UUID
    var name: String
    var minutes: Int
}
