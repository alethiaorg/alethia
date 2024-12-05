//
//  ReaderViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/12/2024.
//

import Foundation
import SwiftData

final class ReaderViewModel: ObservableObject {
    let settings: ChapterSettings
    let chapters: [Chapter]
    @Published var currentIndex: Int
    @Published var currentPage: Int = 0
    @Published var isOverlayVisible: Bool = true
    @Published var currentReadingHistory: ReadingHistory?
    
    // For vertical reader, we need to scroll to certain section first before displaying
    @Published var paintedScreen: Bool = false
    
    init(
        settings: ChapterSettings,
        chapters: [Chapter],
        currentIndex: Int
    ) {
        self.settings = settings
        self.chapters = chapters
        self.currentIndex = currentIndex
    }
    
    var currentChapter: Chapter {
        chapters[currentIndex]
    }
    
    var canGoBack: Bool {
        currentIndex < chapters.count - 1
    }
    
    var canGoForward: Bool {
        currentIndex > 0
    }
    
    func goToPreviousChapter() {
        if canGoBack {
            currentIndex += 1
        }
    }
    
    func goToNextChapter() {
        if canGoForward {
            currentIndex -= 1
        }
    }
    
    func toggleReaderDirection(context: ModelContext) {
        settings.cycleReaderDirection()
        do {
            try context.save()
        }
        catch {
            print("Error Saving Chapter Setting Read Direction")
        }
    }
    
    func createReadingHistory(modelContext: ModelContext, startPage: Int) {
        let newHistory = ReadingHistory(
            startChapter: currentChapter,
            startPage: startPage
        )
        
        modelContext.insert(newHistory)
        currentReadingHistory = newHistory
    }
    
    func updateReadingHistory(modelContext: ModelContext) {
        guard let history = currentReadingHistory else { return }
        
        history.finishSession(
            endPage: currentPage,
            dateEnded: Date(),
            endChapter: currentChapter != history.startChapter ? currentChapter : nil
        )
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save reading history: \(error)")
        }
    }
}
