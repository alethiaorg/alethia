//
//  ContentRating.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/11/2024.
//

import SwiftUI

enum ContentRating: String, CaseIterable, Codable {
    case Safe = "Safe"
    case Suggestive = "Suggestive"
    case Explicit = "Explicit"
    
    var color: Color {
        switch self {
        case .Safe:
            return .appGreen
        case .Suggestive:
            return .appYellow
        case .Explicit:
            return .appRed
        }
    }
}
