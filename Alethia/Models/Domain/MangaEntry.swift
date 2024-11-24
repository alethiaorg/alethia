//
//  MangaEntry.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/11/2024.
//

import Foundation

struct MangaEntry: Hashable, Identifiable {
    var id = UUID()
    
    let sourceId: UUID
    let fetchUrl: String
    
    let title: String
    let coverUrl: String
    
    init(sourceId: UUID, fetchUrl: String, title: String, coverUrl: String) {
        self.sourceId = sourceId
        self.fetchUrl = fetchUrl
        self.title = title
        self.coverUrl = coverUrl
    }
    
    init(id: UUID, sourceId: UUID, fetchUrl: String, title: String, coverUrl: String) {
        self.id = id
        self.sourceId = sourceId
        self.fetchUrl = fetchUrl
        self.title = title
        self.coverUrl = coverUrl
    }
}
