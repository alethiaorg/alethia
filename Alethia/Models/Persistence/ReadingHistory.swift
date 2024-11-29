//
//  ReadingHistory.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/11/2024.
//

import Foundation
import SwiftData

@Model
final class ReadingHistory {
    // MARK: Properties
    
    var startPage: Int
    var endPage: Int?
    var dateStarted: Date
    var dateEnded: Date?
    
    // MARK: Relational Properties
    
    // SwiftData allows for unidirectional relationships so no need to set inverse properties on a chapter
    @Relationship(deleteRule: .cascade) var startChapter: Chapter
    @Relationship(deleteRule: .cascade) var endChapter: Chapter?
    
    // MARK: Initializer
    
    init(
        startChapter: Chapter,
        startPage: Int,
        dateStarted: Date = Date()
    ) {
        self.startChapter = startChapter
        self.startPage = startPage
        self.dateStarted = dateStarted
    }
    
    // MARK: Session Management
    
    func finishSession(endPage: Int, dateEnded: Date, endChapter: Chapter?) {
        self.endPage = endPage
        self.dateEnded = dateEnded
        self.endChapter = endChapter
    }
}
