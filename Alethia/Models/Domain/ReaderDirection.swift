//
//  ReaderDirection.swift
//  Alethia
//
//  Created by Angelo Carasig on 21/11/2024.
//

import Foundation

enum ReaderDirection: CaseIterable {
    case RTL
    case LTR
    case Vertical
    case Webtoon
    
    func cycleReadingDirection() -> ReaderDirection {
        let allCases = ReaderDirection.allCases
        guard let currentIndex = allCases.firstIndex(of: self) else {
            return self
        }
        
        let nextIndex = (currentIndex + 1) % allCases.count
        return allCases[nextIndex]
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
