//
//  GetSearchContent.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/11/2024.
//

import Foundation

func getSearchContent(source: Source, query: String, page: Int = 0) async throws -> [MangaEntry] {
    guard let baseUrl = source.host?.baseUrl,
          let version = source.host?.version,
          !query.isEmpty else {
        throw NetworkError.invalidData
    }
    
    guard var urlComponents = URLComponents(string: URL.appendingPaths(baseUrl, "api", "v\(version)", source.path, "search")?.absoluteString ?? "") else {
        throw NetworkError.missingURL
    }
    
    urlComponents.queryItems = [
        URLQueryItem(name: "query", value: query),
        URLQueryItem(name: "page", value: String(page))
    ]
    
    print("Fetching with query '\(query)' and page '\(page)'")
    
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
