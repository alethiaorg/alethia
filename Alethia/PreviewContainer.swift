//
//  PreviewContainer.swift
//  Alethia
//
//  Created by Angelo Carasig on 16/11/2024.
//

import SwiftUI
import SwiftData

struct PreviewContainer {
    let container: ModelContainer!
    
    let host: Host!
    let manga: Manga!
    
    init(_ types: [any PersistentModel.Type], isStoredInMemoryOnly: Bool = true) {
        let schema = Schema(types)
        let config = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
        self.container = try! ModelContainer(for: schema, configurations: [config])
        
        let host: Host = Host(id: UUID(), name: "Lighthouse", baseUrl: "", version: 1)
        let source: Source = Source(id: UUID(), name: "Mangadex", icon: "", path: "mangadex")
        
        let manga: Manga = Manga(
            title: "Houkagogakari",
            authors: ["Kouda Gakuto", "Meiji"],
            synopsis: """
                    "When the clock strikes midnight, we're trapped in \"After-School.\" In that world, there's no right answer, no end, no \"game clear.\" There’s only our lifeless bodies, stacking up one by one.\nOne day, Kei Nimori, a young elementary school student, suddenly notices his name scrawled on the classroom blackboard, alongside the mysterious words \"After-School Duty.\"\nThus begins a dark, midnight fairy tale of several young boys and girls risking their lives to record and contain monsters in a bizarre realm known as \"After-School.\",
                    """,
            tags: 	[
                "Ghosts",
                "Drama",
                "School Life",
                "Horror",
                "Supernatural",
                "Mystery",
                "Adaptation"
            ]
        )
        
        let alternativeTitle1 = AlternativeTitle(title: "ほうかごがかり", manga: manga)
        let alternativeTitle2 = AlternativeTitle(title: "After-School Duty", manga: manga)
        
        manga.alternativeTitles.append(alternativeTitle1)
        manga.alternativeTitles.append(alternativeTitle2)
        
        let origin: Origin = Origin(
            slug: "fc671773-a9e7-4cb3-810c-eea9f9bfee2b",
            url: "https://mangadex.org/title/fc671773-a9e7-4cb3-810c-eea9f9bfee2b",
            cover: "https://mangadex.org/covers/fc671773-a9e7-4cb3-810c-eea9f9bfee2b/5a554f95-063f-4827-b5bc-dfcbe7ef08e2.jpg",
            rating: 8.778,
            referer: "https://mangadex.org",
            publishStatus: .Ongoing,
            contentRating: .Safe,
            createdAt: Date.parseChapterDate("2024-11-04T09:30:27.000Z"),
            updatedAt: Date.parseChapterDate("2024-11-12T18:12:53.000Z")
        )
        
        let origin2: Origin = Origin(
            slug: "fc671773-a9e7-4cb3-810c-eea9f9bfee2b",
            url: "https://mangadex.org/title/fc671773-a9e7-4cb3-810c-eea9f9bfee2b",
            cover: "https://mangadex.org/covers/fc671773-a9e7-4cb3-810c-eea9f9bfee2b/5a554f95-063f-4827-b5bc-dfcbe7ef08e2.jpg",
            rating: 8.778,
            referer: "https://mangadex.org",
            publishStatus: .Ongoing,
            contentRating: .Safe,
            createdAt: Date.parseChapterDate("2024-11-04T09:30:27.000Z"),
            updatedAt: Date.parseChapterDate("2024-11-12T18:12:53.000Z")
        )
        
        let chapters: [Chapter] = [
            Chapter(title: nil, slug: "e0079287-0a0e-45be-9a43-12affc8abae8", number: 4, scanlator: "Nōgaku", date: Date.parseChapterDate("2024-11-14T08:18:16.000Z")),
            Chapter(title: nil, slug: "e0079287-0a0e-45be-9a43-12affc8abae8", number: 3, scanlator: "Nōgaku", date: Date.parseChapterDate("2024-11-13T05:37:45.000Z")),
            Chapter(title: nil, slug: "e0079287-0a0e-45be-9a43-12affc8abae8", number: 2, scanlator: "Nōgaku", date: Date.parseChapterDate("2024-11-06T18:28:38.000Z")),
            Chapter(title: nil, slug: "e0079287-0a0e-45be-9a43-12affc8abae8", number: 1, scanlator: "Rose Scans", date: Date.parseChapterDate("2024-11-05T13:42:11.000Z")),
            Chapter(title: nil, slug: "e0079287-0a0e-45be-9a43-12affc8abae8", number: 1, scanlator: "Nōgaku", date: Date.parseChapterDate("2024-11-04T09:44:37.000Z"))
        ]
        
        origin.chapters.append(contentsOf: chapters)
        origin2.chapters.append(contentsOf: chapters)
        
        manga.origins.append(origin)
        manga.origins.append(origin2)
        
        source.origins.append(origin)
        source.origins.append(origin2)
        
        host.sources.append(source)
        
        self.host = host
        self.manga = manga
        
        let container = self.container!
        Task { @MainActor in
            container.mainContext.insert(host)
            container.mainContext.insert(manga)
        }
    }
}
