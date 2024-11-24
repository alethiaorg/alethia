//
//  PublishStatus.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/11/2024.
//

import SwiftUI

enum PublishStatus: String, CaseIterable, Codable {
    case Unknown = "Unknown"
    case Ongoing = "Ongoing"
    case Completed = "Completed"
    case Hiatus = "Hiatus"
    case Cancelled = "Cancelled"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .Unknown:
            return .tint
        case .Ongoing:
            return .appBlue
        case .Completed:
            return .appGreen
        case .Hiatus:
            return .appOrange
        case .Cancelled:
            return .appRed
        }
    }
}
