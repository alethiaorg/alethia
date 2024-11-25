//
//  Versions.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/11/2024.
//

import SwiftData
import Foundation

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Host.self, Manga.self, AlternativeTitle.self, Origin.self, Chapter.self, Source.self, SourceRoute.self]
    }
    
    @Model
    final class Host {
        @Attribute(.unique) var id: UUID
        @Attribute(.unique) var name: String
        @Attribute(.unique) var baseUrl: String
        var version: Int
        var sources: [Source] = []
        
        init(id: UUID, name: String, baseUrl: String, version: Int) {
            self.id = id
            self.name = name
            self.baseUrl = baseUrl
            self.version = version
        }
    }
    
    @Model
    final class Manga {
        @Attribute(.unique) var title: String
        var id = UUID()
        var inLibrary: Bool = false
        var authors: [String]
        var synopsis: String
        var tags: [String]
        var origins: [Origin] = []
        var alternativeTitles: [AlternativeTitle] = []
        
        init(title: String, authors: [String], synopsis: String, tags: [String]) {
            self.title = title
            self.authors = authors
            self.synopsis = synopsis
            self.tags = tags
        }
    }
    
    @Model
    final class AlternativeTitle {
        var title: String
        @Relationship(deleteRule: .cascade, inverse: \Manga.alternativeTitles) var manga: Manga?
        
        init(title: String, manga: Manga) {
            self.title = title
            self.manga = manga
        }
    }
    
    @Model
    final class Origin {
        @Relationship(inverse: \Manga.origins) var manga: Manga?
        @Relationship(inverse: \Source.origins) var source: Source?
        var slug: String
        var url: String
        var cover: String
        var rating: Double
        var referer: String
        var publishStatus: String
        var contentRating: String
        var createdAt: Date
        var updatedAt: Date
        var chapters: [Chapter] = []
        
        init(slug: String, url: String, cover: String, rating: Double, referer: String, publishStatus: String, contentRating: String, createdAt: Date, updatedAt: Date) {
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
    }
    
    @Model
    final class Source {
        @Relationship(deleteRule: .cascade, inverse: \Host.sources) var host: Host?
        var id: UUID
        var name: String
        var icon: String
        var path: String
        var pinned: Bool = false
        var origins: [Origin] = []
        var routes: [SourceRoute] = []
        
        init(id: UUID, name: String, icon: String, path: String) {
            self.id = id
            self.name = name
            self.icon = icon
            self.path = path
        }
    }
    
    @Model
    final class SourceRoute {
        @Relationship(inverse: \Source.routes) var source: Source?
        var name: String
        var path: String
        
        init(name: String, path: String) {
            self.name = name
            self.path = path
        }
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Host.self, Manga.self, AlternativeTitle.self, Origin.self, Chapter.self, Source.self, SourceRoute.self]
    }
    
    @Model
    final class Host {
        #Unique<Host>([\.id], [\.name], [\.baseUrl])
        
        @Attribute(.unique) var id: UUID
        @Attribute(.unique) var name: String
        @Attribute(.unique) var baseUrl: String
        var version: Int
        var sources: [Source] = [Source]()
        
        init(id: UUID, name: String, baseUrl: String, version: Int) {
            self.id = id
            self.name = name
            self.baseUrl = baseUrl
            self.version = version
        }
    }
    
    @Model
    final class Manga {
        #Unique<Manga>([\.title])
        #Index<Manga>([\.title])
        
        var id = UUID()
        var inLibrary: Bool = false
        
        @Attribute(.unique) var title: String
        var authors: [String]
        var synopsis: String
        var tags: [String]
        
        var origins: [Origin] = [Origin]()
        var alternativeTitles = [AlternativeTitle]()
        var collections: [Collection] = [Collection]()
        
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
        @Relationship(inverse: \Manga.origins) var manga: Manga?
        @Relationship(inverse: \Source.origins) var source: Source?
        
        /// NOTE: These props may not be unique if they belong to different sources that return the same
        /// TODO: https://stackoverflow.com/a/78640334
        
        var slug: String
        var url: String
        var cover: String
        var rating: Double
        var referer: String
        var publishStatus: PublishStatus
        var contentRating: ContentRating
        var createdAt: Date
        var updatedAt: Date
        var chapters: [Chapter] = []
        
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
    
    @Model
    final class Source {
        @Relationship(deleteRule: .cascade, inverse: \Host.sources) var host: Host?
        
        var id: UUID
        var name: String
        var icon: String
        var path: String
        
        // App-related
        var pinned: Bool = false
        
        var origins: [Origin] = [Origin]()
        var routes: [SourceRoute] = [SourceRoute]()
        
        init(id: UUID, name: String, icon: String, path: String) {
            self.id = id
            self.name = name
            self.icon = icon
            self.path = path
        }
    }
    
    @Model
    final class SourceRoute {
        @Relationship(inverse: \Source.routes) var source: Source?
        var name: String
        var path: String
        
        init(name: String, path: String) {
            self.name = name
            self.path = path
        }
    }
    
    @Model
    final class Collection {
        #Unique<Collection>([\.name])
        
        var id = UUID()
        @Attribute(.unique) var name: String
        @Relationship(deleteRule: .nullify, inverse: \Manga.collections) var mangas: [Manga] = []
        
        init(name: String) {
            self.name = name
        }
        
        @Transient
        var size: Int {
            mangas.filter { $0.inLibrary }.count
        }
    }
}
