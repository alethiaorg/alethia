//
//  DownloadService.swift
//  Alethia
//
//  Created by Angelo Carasig on 28/11/2024.
//

import Foundation
import SwiftData
import ZIPFoundation

final class DownloadService {
    private let networkService: NetworkService
    private let modelContext: ModelContext
    private let fileManager: FileManager
    
    private static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
    
    init(modelContext: ModelContext,
         networkService: NetworkService = NetworkService(),
         fileManager: FileManager = .default) {
        self.modelContext = modelContext
        self.networkService = networkService
        self.fileManager = fileManager
    }
    
    // MARK: - Public Methods
    
    func downloadChapter(_ chapter: Chapter) -> AsyncThrowingStream<DownloadProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Preparing directories
                    continuation.yield(.preparingDirectories)
                    let downloadPath = try createDownloadDirectory(for: chapter)
                    let tempDirectory = try createTempDirectory()
                    defer { try? fileManager.removeItem(at: tempDirectory) }
                    
                    // Fetching content
                    continuation.yield(.fetchingContent)
                    let imageUrls = try await getChapterContent(chapter: chapter)
                    
                    // Download images
                    guard let referer = chapter.origin?.referer else {
                        throw DownloadError.noReferer
                    }
                    
                    try await downloadImages(
                        urls: imageUrls,
                        to: tempDirectory,
                        referer: referer
                    ) { current, total in
                        continuation.yield(.downloadingImages(current: current, total: total))
                    }
                    
                    // Create archive
                    continuation.yield(.creatingArchive)
                    let cbzURL = try createCBZ(
                        from: tempDirectory,
                        outputPath: downloadPath,
                        filename: "\(chapter.id.uuidString).cbz"
                    )
                    
                    // Update chapter path
                    await MainActor.run {
                        chapter.localPath = cbzURL.path
                        try? modelContext.save()
                    }
                    
                    continuation.yield(.completed)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func getChapter(_ chapter: Chapter) async throws -> [String] {
        guard let localPath = chapter.localPath else {
            throw DownloadError.fileNotFound
        }

        let cbzURL = URL(fileURLWithPath: localPath)
        if !fileManager.fileExists(atPath: cbzURL.path) {
            await MainActor.run {
                chapter.localPath = nil
                try? modelContext.save()
            }
            throw DownloadError.fileNotFound
        }
        
        let archive = try Archive(url: cbzURL, accessMode: .read)
        let extractDirectory = try createTempDirectory()
        var imageURLs: [String] = []
        
        let imageExtensions = [
            // most common ones
            "jpg", "jpeg", "png", "webp",
            
            // less common ones to include for compatability
            "gif", "heic", "heif", "tiff", "bmp"
        ]
        
        for entry in archive {
            let fileExtension = entry.path.components(separatedBy: ".").last?.lowercased()
            if let ext = fileExtension, imageExtensions.contains(ext) {
                let fileURL = extractDirectory.appendingPathComponent(entry.path)
                let _ = try archive.extract(entry, to: fileURL)
                imageURLs.append(fileURL.absoluteString)
            }
        }
        
        // Sort by numeric value in filename since they are saved as enumerated ints
        return imageURLs.sorted { url1, url2 in
            let name1 = URL(string: url1)?.deletingPathExtension().lastPathComponent ?? ""
            let name2 = URL(string: url2)?.deletingPathExtension().lastPathComponent ?? ""
            
            // Convert to integers for numeric comparison
            let num1 = Int(name1) ?? 0
            let num2 = Int(name2) ?? 0
            return num1 < num2
        }
    }
    
    func deleteChapter(_ chapter: Chapter) throws {
        guard let localPath = chapter.localPath else {
            throw DownloadError.fileNotFound
        }
        
        let cbzURL = URL(fileURLWithPath: localPath)
        
        // Check if file exists before attempting deletion
        if fileManager.fileExists(atPath: cbzURL.path) {
            try fileManager.removeItem(at: cbzURL)
        }
        
        // Update chapter model
        Task { @MainActor in
            chapter.localPath = nil
            try? modelContext.save()
        }
    }
    
    // MARK: - Private Methods - Networking
    
    private func getChapterContent(chapter: Chapter) async throws -> [String] {
        guard let origin = chapter.origin,
              let source = origin.source,
              let host = source.host
        else {
            throw DownloadError.invalidChapter
        }
        
        guard let url = URL.appendingPaths(host.baseUrl, "api", "v\(host.version)", source.path, "chapter", chapter.slug) else {
            throw NetworkError.invalidData
        }
        
        return try await networkService.request(url: url)
    }
    
    private func downloadImages(
        urls: [String],
        to directory: URL,
        referer: String,
        progress: @escaping (Int, Int) -> Void
    ) async throws {
        var downloadedCount = 0
        let totalCount = urls.count
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (index, urlString) in urls.enumerated() {
                guard let url = URL(string: urlString) else { continue }
                
                group.addTask {
                    let data = try await self.fetchImageData(from: url, referer: referer)
                    let imagePath = directory.appendingPathComponent("\(index).jpg")
                    try data.write(to: imagePath)
                    
                    await MainActor.run {
                        downloadedCount += 1
                        progress(downloadedCount, totalCount)
                    }
                }
            }
            try await group.waitForAll()
        }
    }
    
    private func fetchImageData(from url: URL, referer: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(referer, forHTTPHeaderField: "Referer")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DownloadError.imageDownloadFailed(url)
        }
        
        return data
    }
    
    // MARK: - Private Methods - File Management
    
    private func createDownloadDirectory(for chapter: Chapter) throws -> String {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsPath = documentsPath.appendingPathComponent("Downloads")
        try? fileManager.createDirectory(at: downloadsPath, withIntermediateDirectories: true)
        
        guard let mangaId = chapter.origin?.manga?.id.uuidString else {
            throw DownloadError.noAssociatedManga
        }
        
        let mangaPath = downloadsPath.appendingPathComponent(mangaId)
        try? fileManager.createDirectory(at: mangaPath, withIntermediateDirectories: true)
        
        return mangaPath.path
    }
    
    private func createTempDirectory() throws -> URL {
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        return tempDirectory
    }
    
    private func createCBZ(from directory: URL, outputPath: String, filename: String) throws -> URL {
        let cbzURL = URL(fileURLWithPath: outputPath).appendingPathComponent(filename)
        let directoryURL = cbzURL.deletingLastPathComponent()
        
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        if fileManager.fileExists(atPath: cbzURL.path) {
            do {
                try fileManager.removeItem(at: cbzURL)
            } catch {
                print("Failed to remove existing file: \(error)")
            }
        }
        
        guard fileManager.fileExists(atPath: directory.path) else {
            throw DownloadError.archiveCreationFailed
        }
        
        do {
            try fileManager.zipItem(at: directory, to: cbzURL)
        } catch {
            print("Failed to create zip: \(error)")
            throw DownloadError.archiveCreationFailed
        }
        
        guard fileManager.fileExists(atPath: cbzURL.path) else {
            throw DownloadError.archiveCreationFailed
        }
        
        return cbzURL
    }
}
