//
//  ChapterListViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 29/11/2024.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
final class ChapterListViewModel {
    let manga: Manga
    var unified: [Chapter]
    
    var continueChapterIndex: Int? {
        unified.lastIndex(where: { $0.progress != 1 })
    }
    
    init(manga: Manga) {
        self.manga = manga
        self.unified = manga.getUnifiedChapterList()
    }
    
    func toggleSortOption(context: ModelContext, option: ChapterSortOption) {
        let sortOption = manga.chapterSettings.sortOption
        
        if sortOption == option {
            // If the same option is selected, toggle the direction
            manga.chapterSettings.sortDirection.toggle()
        } else {
            // If a new option is selected, set it to descending
            manga.chapterSettings.sortOption = option
            manga.chapterSettings.sortDirection = .descending
        }
        
        do {
            try context.save()
        }
        catch {
            print("Error updating sort direction in chapter list.")
        }
        
        withAnimation {
            updateChapters()
        }
    }
    
    enum Direction {
        case previous
        case next
    }
    
    func markAll(modelContext: ModelContext, startingFrom chapter: Chapter, isRead: Bool, direction: Direction) {
        let chapters = manga.getUnifiedChapterList()
        guard let index = chapters.firstIndex(where: { $0.id == chapter.id }) else { return }
        
        let range: Range<Int>
        switch direction {
        case .previous:
            range = 0..<index + 1
        case .next:
            range = index..<chapters.count
        }
        
        for i in range {
            chapters[i].progress = isRead ? 1.0 : 0.0
        }
        
        try? modelContext.save()
    }
    
    func updateChapters() -> Void {
        unified = manga.getUnifiedChapterList()
    }
    
    func updateOriginPriority(context: ModelContext, from: Int, to: Int) {
        let chapterSettings = manga.chapterSettings
        
        var sortedPriorities = chapterSettings.originPriorities.sorted { $0.priority < $1.priority }
        
        let movedPriority = sortedPriorities.remove(at: from)
        sortedPriorities.insert(movedPriority, at: to)
        
        for (index, priority) in sortedPriorities.enumerated() {
            priority.priority = index
        }
        
        manga.chapterSettings.originPriorities = sortedPriorities
        
        do {
            try context.save()
        } catch {
            print("Error saving context after updating origin priorities: \(error)")
        }
        
        updateChapters()
        print("Updated Origin Priorities:")
        for origin in sortedPriorities {
            print("\(origin.origin?.slug ?? "NO SLUG") - \(origin.priority)")
        }
    }
    
    func updateScanlatorPriority(context: ModelContext, from: Int, to: Int) {
        let chapterSettings = manga.chapterSettings
        
        var sortedPriorities = chapterSettings.scanlatorPriorities.sorted { $0.priority < $1.priority }
        
        let movedPriority = sortedPriorities.remove(at: from)
        sortedPriorities.insert(movedPriority, at: to)
        
        for (index, priority) in sortedPriorities.enumerated() {
            priority.priority = index
        }
        
        manga.chapterSettings.scanlatorPriorities = sortedPriorities
        
        do {
            try context.save()
        } catch {
            print("Error saving context after updating origin priorities: \(error)")
        }
        
        updateChapters()
        print("Updated Origin Priorities:")
        for origin in sortedPriorities {
            print("\(origin.source?.name ?? "NO NAME") - \(origin.priority)")
        }
    }
}
