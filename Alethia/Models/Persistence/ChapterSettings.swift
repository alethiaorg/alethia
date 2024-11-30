//
//  ChapterSettings.swift
//  Alethia
//
//  Created by Angelo Carasig on 29/11/2024.
//

import Foundation
import SwiftData

// MARK: - Enums

enum ChapterSortOption: String, CaseIterable, Codable {
    case number = "Number"
    case date = "Date"
}

enum ChapterSortDirection: String, CaseIterable, Codable {
    case descending = "Descending"
    case ascending = "Ascending"
    
    mutating func toggle() {
        self = (self == .ascending) ? .descending : .ascending
    }
}

// MARK: - ChapterSettings Model

@Model
final class ChapterSettings {
    // MARK: Properties
    
    var readDirection: ReaderDirection = ReaderDirection.LTR
    var sortOption: ChapterSortOption
    var sortDirection: ChapterSortDirection
    var showAll: Bool = false
    var showHalfChapters: Bool = true
    
    // MARK: Relational Properties
    
    @Relationship(deleteRule: .cascade) var originPriorities: [OriginPriority] = []
    @Relationship(deleteRule: .cascade) var scanlatorPriorities: [ScanlatorPriority] = []
    @Relationship(deleteRule: .cascade, inverse: \Manga.chapterSettings) var manga: Manga?
    
    // MARK: Initializer
    
    init(
        sortOption: ChapterSortOption = .number,
        sortDirection: ChapterSortDirection = .descending
    ) {
        self.sortOption = sortOption
        self.sortDirection = sortDirection
    }
}

extension ChapterSettings {
    func cycleReaderDirection() {
        readDirection.cycleReadingDirection()
    }
    
    func mangaOriginsChanged(_ caller: Manga) {
        guard let manga = manga, manga.id == caller.id else { return }
        
        updateOriginPriorities(for: manga)
        updateScanlatorPriorities(for: manga)
    }
    
    private func updateOriginPriorities(for manga: Manga) {
        // Update existing priorities and add new ones
        originPriorities = manga.origins.enumerated().map { index, origin in
            if let existingPriority = originPriorities.first(where: { $0.origin?.id == origin.id }) {
                existingPriority.priority = index
                return existingPriority
            } else {
                return OriginPriority(origin: origin, priority: index)
            }
        }
    }
    
    private func updateScanlatorPriorities(for manga: Manga) {
        let scanlatorInfo = manga.origins.enumerated().flatMap { (originIndex, origin) -> [(String, Source, Int)] in
            guard let source = origin.source else { return [] }
            return origin.chapters.map { ($0.scanlator, source, originIndex) }
        }
        
        let scanlatorData = Dictionary(grouping: scanlatorInfo, by: { $0.0 })
            .mapValues { values in
                (source: values.first!.1, priority: values.map { $0.2 }.min()!)
            }
        
        let existingPriorities = Dictionary(uniqueKeysWithValues: scanlatorPriorities.map { ($0.scanlator, $0) })
        
        scanlatorPriorities = scanlatorData.keys.enumerated().map { (index, scanlator) in
            if let existing = existingPriorities[scanlator] {
                existing.source = scanlatorData[scanlator]!.source
                return existing
            } else {
                return ScanlatorPriority(
                    scanlator: scanlator,
                    source: scanlatorData[scanlator]!.source,
                    priority: scanlatorPriorities.count + index
                )
            }
        }
        
        scanlatorPriorities.sort { a, b in
            if a.priority != b.priority {
                return a.priority < b.priority
            }
            return scanlatorData[a.scanlator]!.priority < scanlatorData[b.scanlator]!.priority
        }
    }
}



// MARK: - OriginPriority Model

@Model
final class OriginPriority {
    // MARK: Properties
    
    @Attribute(.unique) var id: UUID
    var priority: Int
    
    // MARK: Relational Properties
    
    @Relationship var origin: Origin?
    @Relationship(deleteRule: .cascade, inverse: \ChapterSettings.originPriorities) var chapterSettings: ChapterSettings?
    
    // MARK: Initializer
    
    init(origin: Origin, priority: Int) {
        self.id = UUID()
        self.origin = origin
        self.priority = priority
    }
}

// MARK: - ScanlatorPriority Model

@Model
final class ScanlatorPriority {
    // MARK: Properties
    
    @Attribute(.unique) var id: UUID
    var scanlator: String
    var icon: String?
    var priority: Int
    
    // MARK: Relational Properties
    @Relationship var source: Source?
    @Relationship(deleteRule: .cascade, inverse: \ChapterSettings.scanlatorPriorities) var chapterSettings: ChapterSettings?
    
    // MARK: Initializer
    
    init(scanlator: String, source: Source, priority: Int) {
        self.id = UUID()
        self.scanlator = scanlator
        self.source = source
        self.priority = priority
    }
}

