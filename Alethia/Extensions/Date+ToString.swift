//
//  Date+ToString.swift
//  Alethia
//
//  Created by Angelo Carasig on 16/11/2024.
//

import Foundation

extension Date {
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d'<ordinal>' MMMM, yyyy"
        
        let day = Calendar.current.component(.day, from: self)
        let ordinalSuffix: String
        
        switch day {
        case 1, 21, 31:
            ordinalSuffix = "st"
        case 2, 22:
            ordinalSuffix = "nd"
        case 3, 23:
            ordinalSuffix = "rd"
        default:
            ordinalSuffix = "th"
        }
        
        let formattedString = formatter.string(from: self)
        return formattedString.replacingOccurrences(of: "<ordinal>", with: ordinalSuffix)
    }
    
    func toRelativeString() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: now)
        
        if let year = components.year, year > 0 {
            return year == 1 ? "1 year ago" : "\(year) years ago"
        } else if let month = components.month, month > 0 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        } else if let day = components.day, day > 0 {
            if day == 1 { return "Yesterday" }
            if day < 7 { return "\(day) days ago" }
            let weeks = day / 7
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else if let second = components.second, second > 0 {
            return second == 1 ? "1 second ago" : "\(second) seconds ago"
        } else {
            return "Just now"
        }
    }
}
