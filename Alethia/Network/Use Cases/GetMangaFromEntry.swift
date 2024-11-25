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
func getMangaFromEntry(entry: MangaEntry, context: ModelContext, insert: Bool = true) async throws -> Manga {
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
    
    manga.collections.append(defaultCollection)
    
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
        
        origin.source = source
        origin.manga = manga
        
        for chapterDTO in originDTO.chapters {
            print("Date for Chapter \(chapterDTO.number) - \(chapterDTO.date)")
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
    
    if insert {
        context.insert(manga)
        try context.save()
    }
    return manga
}
