//
//  Manga.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/11/2024.
//

import Foundation
import SwiftData

@Model
final class Manga {
    // MARK: Definitions - Unique and Indexed Definitions
    #Unique<Manga>([\.title])
    #Index<Manga>([\.title])
    
    // MARK: Properties
    
    var id = UUID()
    var inLibrary: Bool = false
    
    @Attribute(.unique) var title: String
    var authors: [String]
    var synopsis: String
    var tags: [String]
    
    // MARK: Relational Properties
    
    // Always init on new manga
    var chapterSettings: ChapterSettings = ChapterSettings(
        sortOption: .number,
        sortDirection: .descending
    )
    
    var origins: [Origin] = [Origin]()
    
    var alternativeTitles = [AlternativeTitle]()
    var collections: [Collection] = [Collection]()
    
    // MARK: Transient (Computed) Properties
    
    @Transient
    var firstOriginUpdatedAt: Date {
        getFirstOrigin().updatedAt
    }
    
    @Transient // to trigger setting update in notificationCenter
    var needsSettingsUpdate: Bool = false
    
    // MARK: Initializer
    
    init(title: String, authors: [String], synopsis: String, tags: [String]) {
        self.title = title
        self.authors = authors
        self.synopsis = synopsis
        self.tags = tags
    }
    
    // MARK: Utility Functions
    
    func toMangaEntry() throws -> MangaEntry {
        let priority = getFirstOrigin()
        
        guard let source = priority.source else {
            throw AppError.noSource(priority)
        }
        
        guard let baseUrl = source.host?.baseUrl,
              let version = source.host?.version else {
            throw NetworkError.invalidData
        }
        
        return MangaEntry(
            id: self.id,
            sourceId: source.id,
            fetchUrl: URL.appendingPaths(baseUrl, "api", "v\(version)", source.path, "manga", priority.slug)!.absoluteString,
            title: self.title,
            coverUrl: priority.cover
        )
    }
    
    // O(n log n) yay
    func getUnifiedChapterList() -> [Chapter] {
        let allChapters = origins.flatMap { origin in
            origin.chapters.filter { chapterSettings.showHalfChapters || isWholeChapter(number: $0.number) }
        }
        
        let sortedChapters = allChapters.sorted { (c1, c2) in
            let compare: (Chapter, Chapter) -> Bool = chapterSettings.sortOption == .number
                ? { $0.number < $1.number }
                : { $0.date < $1.date }
            return chapterSettings.sortDirection == .ascending ? compare(c1, c2) : compare(c2, c1)
        }
        
        guard !chapterSettings.showAll else { return sortedChapters }
        
        return sortedChapters.reduce(into: []) { (result, chapter) in
            if let existingIndex = result.firstIndex(where: { $0.number == chapter.number }) {
                if shouldReplace(existing: result[existingIndex], with: chapter) {
                    result[existingIndex] = chapter
                }
            } else {
                result.append(chapter)
            }
        }
    }
    
    func getFirstOrigin() -> Origin {
        guard let origin = self.origins.min(by: { $0.priority < $1.priority }) else {
            fatalError("\(title) contains no origins.")
        }
        
        return origin
    }
    
    func updateOriginOrder(newDefaultOrigin: Origin) -> Void {
        guard origins.contains(where: { $0.id == newDefaultOrigin.id }) else {
            fatalError("The provided origin (\(newDefaultOrigin.slug)) is not part of the manga's origins.")
        }
        
        newDefaultOrigin.priority = 0
        
        var currentPriority = 1
        for origin in origins where origin.id != newDefaultOrigin.id {
            origin.priority = currentPriority
            currentPriority += 1
        }
    }
    
    func updateMetadataFromTransient(_ manga: Manga) -> Void {
        self.title = manga.title
        self.authors = manga.authors
        self.synopsis = manga.synopsis
        
        self.updateTags(with: manga.tags)
        self.updateAlternativeTitles(with: manga.alternativeTitles)
    }
    
    func updateTags(with newTags: [String]) {
        let lowercasedExistingTags = Set(self.tags.map { $0.lowercased() })
        let uniqueNewTags = newTags.filter { !lowercasedExistingTags.contains($0.lowercased()) }
        self.tags.append(contentsOf: uniqueNewTags)
        self.tags.sort { $0.lowercased() < $1.lowercased() }
    }
    
    func updateAlternativeTitles(with newTitles: [AlternativeTitle]) {
        let lowercasedExistingTitles = Set(self.alternativeTitles.map { $0.title.lowercased() })
        let uniqueNewTitles = newTitles.filter { !lowercasedExistingTitles.contains($0.title.lowercased()) }
        
        self.alternativeTitles.append(contentsOf: uniqueNewTitles)
        self.alternativeTitles.sort { $0.title.lowercased() < $1.title.lowercased() }
        
        for title in self.alternativeTitles {
            title.manga = self
        }
    }
    
    func originsDidChange() -> Void {
        chapterSettings.mangaOriginsChanged(self)
    }
}

// MARK: Private Utility Functions
private extension Manga {
    
    // Utils for unified chapter calculation
    
    private func isWholeChapter(number: Double) -> Bool {
        let fractionalPart = number.truncatingRemainder(dividingBy: 1)
        return abs(fractionalPart) < 0.001 || abs(1 - fractionalPart) < 0.001
    }

    private func shouldReplace(existing: Chapter, with new: Chapter) -> Bool {
        let existingOriginPriority = chapterSettings.originPriorities.first { $0.origin?.id == existing.origin?.id }?.priority ?? Int.max
        let newOriginPriority = chapterSettings.originPriorities.first { $0.origin?.id == new.origin?.id }?.priority ?? Int.max
        
        if newOriginPriority != existingOriginPriority {
            return newOriginPriority < existingOriginPriority
        }
        
        let existingScanlatorPriority = chapterSettings.scanlatorPriorities.first { $0.scanlator == existing.scanlator }?.priority ?? Int.max
        let newScanlatorPriority = chapterSettings.scanlatorPriorities.first { $0.scanlator == new.scanlator }?.priority ?? Int.max
        return newScanlatorPriority < existingScanlatorPriority
    }
}
