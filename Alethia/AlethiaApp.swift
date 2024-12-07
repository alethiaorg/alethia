//
//  AlethiaApp.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/11/2024.
//

import SwiftUI
import SwiftData

@main
struct AlethiaApp: App {
    
    /// TODO: Feature (Smart Groups) -
    /// When toggling inLibrary, also append to a Collection if certain conditions hold true:-
    /// Matches tag names (AND | OR)
    ///
    /// TODO: Bug -
    /// When in viewing manga details from source tab, if priority was modified the cover image
    /// will continue to be the one that was loaded from sources, even if the firstOrigin changes
    
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                // API Stuff
                Host.self, Source.self, SourceRoute.self,
                
                // Main Stuff
                Manga.self, Origin.self, Chapter.self, AlternativeTitle.self,
                
                // Collection/Tracking Stuff
                Collection.self, ReadingHistory.self,
                
                // Chapter Setting Stuff
                ChapterSettings.self, OriginPriority.self, ScanlatorPriority.self
            ])
            
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
            createDefaultCollection()
        } catch {
            fatalError("Could not create container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)        
    }
}

// MARK: Database Seeding

private extension AlethiaApp {
    private func createDefaultCollection() -> Void {
        let context = container.mainContext
        
        let groupFetchDescriptor = FetchDescriptor<Collection>(predicate: #Predicate { $0.name == "Default" })
        let defaultCollection: Collection
        
        // Fetch or create default collection
        do {
            if let existingCollection = try context.fetch(groupFetchDescriptor).first {
                defaultCollection = existingCollection
            } else {
                defaultCollection = Collection(name: "Default")
                context.insert(defaultCollection)
            }
        } catch {
            print("Failed to fetch or create Default group: \(error.localizedDescription)")
            return
        }
        
        let mangaDescriptor = FetchDescriptor<Manga>(predicate: #Predicate { $0.collections.isEmpty })
        
        // Seed all empty with default collection
        do {
            let ungrouped = try context.fetch(mangaDescriptor)
            
            for manga in ungrouped {
                manga.collections.append(defaultCollection)
            }
            
            try context.save()
        }
        catch {
            print("Failed to create Default group: \(error.localizedDescription)")
        }
    }
}
