//
//  MangaDTO.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/11/2024.
//

import Foundation

struct MangaDTO: Codable {
    let hostSlug, sourceSlug, mangaSlug: String
    let title: String
    let alternativeTitles, authors: [String]
    let synopsis: String
    let tags: [String]
    let sources: [originDTO]
}

struct originDTO: Codable {
    let hostSlug, sourceSlug, mangaSlug: String
    let url: String
    let coverUrl: String
    let referer: String
    let publishingStatus: String
    let rating: Double
    let createdAt, updatedAt: String
    let chapters: [ChapterDTO]
}

struct ChapterDTO: Codable {
    let hostSlug, sourceSlug, mangaSlug, chapterSlug: String
    let title: String?
    let number: Double
    let scanlator, date: String
}
