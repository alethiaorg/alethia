//
//  DownloadImage.swift
//  Alethia
//
//  Created by Angelo Carasig on 21/11/2024.
//

import Foundation
import Kingfisher

func downloadImage(name: String, url: URL) async -> String? {
    await withCheckedContinuation { continuation in
        let downloader = ImageDownloader.default
        
        downloader.downloadImage(with: url, options: nil) { result in
            switch result {
            case .success(let value):
                let image = value.image
                
                if let imageData = image.pngData() {
                    let fileManager = FileManager.default
                    let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let fileName = name + ".png"
                    let fileURL = documentDirectory.appendingPathComponent(fileName)
                    
                    do {
                        try imageData.write(to: fileURL)
                        continuation.resume(returning: fileURL.path)
                    } catch {
                        print("Error saving image to file: \(error)")
                        continuation.resume(returning: nil)
                    }
                } else {
                    print("Failed to convert image to PNG data.")
                    continuation.resume(returning: nil)
                }
                
            case .failure(let error):
                print("Image download failed: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
}
