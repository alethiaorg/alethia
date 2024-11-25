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
    
    /// TODO: Smart Groups -
    /// When toggling inLibrary, also append to a Collection if certain conditions hold true:-
    /// Matches tag names (AND | OR)
    ///
    
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([Host.self, Source.self, SourceRoute.self,
                                 Manga.self, Origin.self, Chapter.self, AlternativeTitle.self,
                                 Collection.self])
            
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
