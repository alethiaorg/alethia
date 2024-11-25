//
//  AppError.swift
//  Alethia
//
//  Created by Angelo Carasig on 21/11/2024.
//

import Foundation

enum AppError: Error {
    case noOrigin(_ manga: Manga)
    case noSource(_ origin: Origin)
    case duplicateHost
    case chapterError
    case noDefaultCollection
    
    var errorDescription: String? {
        switch self {
        case .noOrigin(let manga):
            return "No Origins Present for this Manga (\(manga.title))."
            
        case .noSource(let origin):
            return "No Source Exists for this Origin (\(origin.slug)."
            
        case .duplicateHost:
            return "This host is already in Alethia."
            
        case .chapterError:
            return "Chapter is missing relational properties origin, source or host."
            
        case .noDefaultCollection:
            return "Default Collection was unable to be found."
        }
    }
}
