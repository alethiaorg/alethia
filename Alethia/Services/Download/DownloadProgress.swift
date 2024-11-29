//
//  DownloadProgress.swift
//  Alethia
//
//  Created by Angelo Carasig on 28/11/2024.
//

import Foundation

enum DownloadProgress {
    case preparingDirectories
    case fetchingContent
    case downloadingImages(current: Int, total: Int)
    case creatingArchive
    case completed
    
    var description: String {
        switch self {
        case .preparingDirectories:
            return "Preparing directories..."
        case .fetchingContent:
            return "Fetching chapter content..."
        case .downloadingImages(let current, let total):
            return "Downloading images (\(current)/\(total))"
        case .creatingArchive:
            return "Creating archive..."
        case .completed:
            return "Download completed"
        }
    }
    
    var progress: Double {
        switch self {
        case .preparingDirectories:
            return 0.1
        case .fetchingContent:
            return 0.2
        case .downloadingImages(let current, let total):
            let baseProgress = 0.2
            let downloadProgress = Double(current) / Double(total) * 0.7 // 70% of total progress
            return baseProgress + downloadProgress
        case .creatingArchive:
            return 0.9
        case .completed:
            return 1.0
        }
    }
}
