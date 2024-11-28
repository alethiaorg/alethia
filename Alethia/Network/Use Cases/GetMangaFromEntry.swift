//
//  GetMangaFromEntry.swift
//  Alethia
//
//  Created by Angelo Carasig on 23/11/2024.
//

import Foundation
import SwiftData

/// Save model to context when fetched so subsequent calls won't need refetch
@MainActor
func getMangaFromEntry(entry: MangaEntry, context: ModelContext, transient: Bool = false, insert: Bool = true) async throws -> Manga {
    let ns = NetworkService()
    
    guard let url = URL(string: entry.fetchUrl) else {
        throw NetworkError.invalidData
    }
    
    let sourceId = entry.sourceId
    let sourceDescriptor = FetchDescriptor<Source>(
        predicate: #Predicate { $0.id == sourceId }
    )
    
    guard let source = try context.fetch(sourceDescriptor).first else {
        throw NetworkError.invalidData
    }
    
    let collectionDescriptor = FetchDescriptor<Collection>(predicate: #Predicate { $0.name == "Default" })
    guard let defaultCollection = try context.fetch(collectionDescriptor).first else {
        throw AppError.noDefaultCollection
    }
    
    let mangaDTO: MangaDTO = try await ns.request(url: url)
    
    let manga = Manga(
        title: mangaDTO.title,
        authors: mangaDTO.authors,
        synopsis: mangaDTO.synopsis,
        tags: mangaDTO.tags
    )
    
    if !transient {
        print("Setting manga default collection")
        manga.collections.append(defaultCollection)
    }
    
    mangaDTO.alternativeTitles.forEach {
        manga.alternativeTitles.append(AlternativeTitle(title: $0, manga: manga))
    }
    
    for originDTO in mangaDTO.sources {
        let origin = Origin(
            slug: originDTO.mangaSlug,
            url: originDTO.url,
            cover: originDTO.coverUrl,
            rating: originDTO.rating,
            referer: originDTO.referer,
            publishStatus: .Unknown,
            contentRating: .Safe,
            createdAt: Date.parseChapterDate(originDTO.createdAt),
            updatedAt: Date.parseChapterDate(originDTO.updatedAt)
        )
        
        if !transient {
            print("Setting new origin source to \(source.name)")
            origin.source = source
        }
        
        origin.manga = manga
        
        for chapterDTO in originDTO.chapters {
            let chapter = Chapter(
                title: chapterDTO.title,
                slug: chapterDTO.chapterSlug,
                number: Double(chapterDTO.number),
                scanlator: chapterDTO.scanlator,
                date: Date.parseChapterDate(chapterDTO.date)
            )
            
            chapter.origin = origin
            
            origin.chapters.append(chapter)
        }
        
        manga.origins.append(origin)
    }
    
    let defaultOrigin = manga.getFirstOrigin()
    
    manga.updateOriginOrder(newDefaultOrigin: defaultOrigin)
    
    if insert {
        print("In Get Manga From Entry: Insert is True! Inserting Manga to Context and Saving...")
        context.insert(manga)
        try context.save()
    }
    return manga
}
