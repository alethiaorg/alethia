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
    #Unique<Manga>([\.title])
    #Index<Manga>([\.title])
    
    var id = UUID()
    var inLibrary: Bool = false
    
    var title: String
    var authors: [String]
    var synopsis: String
    var tags: [String]
    
    var origins: [Origin] = [Origin]()
    var alternativeTitles = [AlternativeTitle]()
    
    @Transient
    var firstOriginUpdatedAt: Date {
        origins.first?.updatedAt ?? Date.distantPast
    }
    
    init(title: String, authors: [String], synopsis: String, tags: [String]) {
        self.title = title
        self.authors = authors
        self.synopsis = synopsis
        self.tags = tags
    }
    
    func toMangaEntry() throws -> MangaEntry {
        guard let origin = origins.first else {
            throw AppError.noOrigin(self)
        }
        
        guard let source = origin.source else {
            throw AppError.noSource(origin)
        }
        
        guard let baseUrl = source.host?.baseUrl,
              let version = source.host?.version else {
            throw NetworkError.invalidData
        }
        
        return MangaEntry(
            id: self.id,
            sourceId: source.id,
            fetchUrl: URL.appendingPaths(baseUrl, "api", "v\(version)", source.path, "manga", origin.slug)!.absoluteString,
            title: self.title,
            coverUrl: origin.cover
        )
    }
}

@Model
final class AlternativeTitle {
    #Index<AlternativeTitle>([\.title])
    
    var title: String
    @Relationship(deleteRule: .cascade, inverse: \Manga.alternativeTitles) var manga: Manga?
    
    init(title: String, manga: Manga) {
        self.title = title
        self.manga = manga
    }
}

@Model
final class Origin {
    #Index<Origin>([\.rating], [\.updatedAt], [\.createdAt])
    
    @Relationship(inverse: \Manga.origins) var manga: Manga?
    @Relationship(inverse: \Source.origins) var source: Source?
    
    var slug: String
    var url: String
    var cover: String
    var rating: Double
    var referer: String
    // TODO: https://stackoverflow.com/a/78640334
    var publishStatus: PublishStatus
    var contentRating: ContentRating
    var createdAt: Date
    var updatedAt: Date
    
    var chapters: [Chapter] = [Chapter]()
    
    init(slug: String, url: String, cover: String, rating: Double, referer: String, publishStatus: PublishStatus, contentRating: ContentRating, createdAt: Date, updatedAt: Date) {
        self.slug = slug
        self.url = url
        self.cover = cover
        self.rating = rating
        self.referer = referer
        self.publishStatus = publishStatus
        self.contentRating = contentRating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class Chapter {
    #Index<Chapter>([\.number], [\.date], [\.scanlator])
    
    @Relationship(inverse: \Origin.chapters) var origin: Origin?
    
    var title: String?
    var slug: String
    var number: Double
    var scanlator: String
    var date: Date
    
    init(title: String?, slug: String, number: Double, scanlator: String, date: Date) {
        self.title = title
        self.slug = slug
        self.number = number
        self.scanlator = scanlator
        self.date = date
    }
    
    func toString() -> String {
        let chapterNumber = number.toString()
        
        if let title = title, !title.isEmpty {
            return "Chapter \(chapterNumber) - \(title)"
        } else {
            return "Chapter \(chapterNumber)"
        }
    }
}
