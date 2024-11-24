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
    /// When toggling inLibrary, also append to a Group if certain conditions hold true:-
    /// Matches tag names (AND | OR)
    /// 

    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([Host.self, Source.self, SourceRoute.self,
                                 Manga.self, Origin.self, Chapter.self, AlternativeTitle.self])
            
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
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
