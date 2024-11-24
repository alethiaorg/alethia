//
//  MangaEntryDTO.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/11/2024.
//

import Foundation

struct MangaEntryDTO: Codable {
    let hostSlug: String
    let sourceSlug: String
    let mangaSlug: String
    let title: String
    let coverUrl: String
}
