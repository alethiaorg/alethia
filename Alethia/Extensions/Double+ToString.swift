//
//  Double+ToString.swift
//  Alethia
//
//  Created by Angelo Carasig on 16/11/2024.
//

import Foundation

extension Double {
    func toString() -> String {
        return truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}
