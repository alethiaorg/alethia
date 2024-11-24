//
//  GetChapterContent.swift
//  Alethia
//
//  Created by Angelo Carasig on 21/11/2024.
//

import Foundation

/// Returns array of URLs of the chapter images in order
func getChapterContent(chapter: Chapter) async throws -> [String] {
    guard let origin = chapter.origin,
          let source = origin.source,
          let host = source.host
    else {
        throw AppError.chapterError
    }
    
    guard let url = URL.appendingPaths(host.baseUrl, "api", "v\(host.version)", source.path, "chapter", chapter.slug) else {
        throw NetworkError.invalidData
    }
    
    let ns = NetworkService()
    
    return try await ns.request(url: url)
}
