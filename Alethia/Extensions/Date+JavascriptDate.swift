//
//  Date+JavascriptDate.swift
//  Alethia
//
//  Created by Angelo Carasig on 16/11/2024.
//

import Foundation

extension Date {
    static func parseChapterDate(_ dateString: String) -> Date {
        // First try ISO8601 with formatter
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        
        // If that fails, try with DateFormatter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // If both fail, log the problematic date string and return distant past
        print("⚠️ Failed to parse date string: \(dateString)")
        return .distantPast
    }
}
