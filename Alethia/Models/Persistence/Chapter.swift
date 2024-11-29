//
//  Chapter.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/11/2024.
//

import Foundation
import SwiftData

@Model
final class Chapter {
    // MARK: Definitions - Indexed Definitions
    #Index<Chapter>([\.number], [\.date], [\.scanlator])
    
    // MARK: Properties
    
    var id = UUID()
    var title: String?
    var slug: String
    var number: Double
    var scanlator: String
    var date: Date
    var localPath: String?
    
    // MARK: Progress Tracking
    
    /// To calculate page number to start from progress -> totalPages * progress
    /// progress from 0...1
    var progress: Double = 0.0
    
    // MARK: Relational Properties
    
    @Relationship(inverse: \Origin.chapters) var origin: Origin?
    
    // MARK: Transient (Computed) Properties
    
    @Transient
    var isDownloaded: Bool {
        localPath != nil
    }
    
    @Transient
    var read: Bool {
        progress == 1.0
    }
    
    // MARK: Initializer
    
    init(title: String?, slug: String, number: Double, scanlator: String, date: Date) {
        self.title = title
        self.slug = slug
        self.number = number
        self.scanlator = scanlator
        self.date = date
    }
    
    // MARK: Utility Functions
    
    func toString() -> String {
        let chapterNumber = number.toString()
        
        if let title = title, !title.isEmpty {
            return "Chapter \(chapterNumber) - \(title)"
        } else {
            return "Chapter \(chapterNumber)"
        }
    }
}
