//
//  ReaderDirection.swift
//  Alethia
//
//  Created by Angelo Carasig on 21/11/2024.
//

import Foundation

enum ReaderDirection: String, CaseIterable, Codable {
    case RTL = "RightToLeft"
    case LTR = "LeftToRight"
    case Vertical = "Vertical"
    case Webtoon = "Webtoon"
    
    mutating func cycleReadingDirection() {
        switch self {
        case .LTR:
            self = .RTL
        case .RTL:
            self = .Vertical
        case .Vertical:
            self = .Webtoon
        case .Webtoon:
            self = .LTR
        }
    }
    
    var isVertical: Bool {
        switch self {
        case .Vertical, .Webtoon:
            return true
        case .RTL, .LTR:
            return false
        }
    }
    
    var systemImageName: String {
        switch self {
        case .RTL:
            return "rectangle.lefthalf.inset.filled.arrow.left"
        case .LTR:
            return "rectangle.righthalf.inset.filled.arrow.right"
        case .Vertical:
            return "platter.filled.bottom.and.arrow.down.iphone"
        case .Webtoon:
            return "arrow.down.app.fill"
        }
    }
}

