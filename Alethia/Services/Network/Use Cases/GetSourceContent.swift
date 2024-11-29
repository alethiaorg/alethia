//
//  GetSourceContent.swift
//  Alethia
//
//  Created by Angelo Carasig on 21/11/2024.
//

import Foundation

func getSourceContent(source: Source, route: String, page: Int = 0) async throws -> [MangaEntry] {
    guard let baseUrl = source.host?.baseUrl,
          let version = source.host?.version else {
        throw NetworkError.invalidData
    }
    
    guard var urlComponents = URLComponents(string: URL.appendingPaths(baseUrl, "api", "v\(version)", source.path, route)?.absoluteString ?? "") else {
        throw NetworkError.missingURL
    }
    
    urlComponents.queryItems = [URLQueryItem(name: "page", value: String(page))]
    
    guard let url = urlComponents.url else {
        throw NetworkError.missingURL
    }
    
    let ns = NetworkService()
    
    let result: [MangaEntryDTO] = try await ns.request(url: url)
    
    return result.map { dto in
        MangaEntry(
            sourceId: source.id,
            fetchUrl: URL.appendingPaths(baseUrl, "api", "v\(version)", source.path, "manga", dto.mangaSlug)!.absoluteString,
            title: dto.title,
            coverUrl: dto.coverUrl
        )
    }
}

