//
//  DownloadError.swift
//  Alethia
//
//  Created by Angelo Carasig on 28/11/2024.
//

import Foundation

enum DownloadError: Error {
    case noAssociatedManga
    case noReferer
    case invalidChapter
    case downloadFailed
    case fileNotFound
    case extractionFailed
    case archiveCreationFailed
    case imageDownloadFailed(URL)
    
    var errorDescription: String? {
        switch self {
        case .noAssociatedManga: return "No manga relation to this chapter found."
        case .noReferer: return "No referer found for chapter's origin."
        case .invalidChapter: return "Invalid chapter information"
        case .downloadFailed: return "Failed to download chapter"
        case .fileNotFound: return "Downloaded file not found"
        case .extractionFailed: return "Failed to extract chapter content"
        case .archiveCreationFailed: return "Failed to create archive"
        case .imageDownloadFailed(let url): return "Failed to download image from: \(url)"
        }
    }
}
