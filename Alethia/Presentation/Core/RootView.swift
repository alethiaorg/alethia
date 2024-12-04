//
//  RootView.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/11/2024.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            HomeRootView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            LibraryRootView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Library")
                }
            
            SourceRootView()
                .tabItem {
                    Image(systemName: "plus.square.dashed")
                    Text("Sources")
                }
            
            HistoryRootView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            
            SettingsRootView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { notification in
            guard let userInfo = notification.userInfo else { return }
            
            let insertedIdentifiers = (userInfo["inserted"] as? [PersistentIdentifier]) ?? []
            let deletedIdentifiers = (userInfo["deleted"] as? [PersistentIdentifier]) ?? []
            let updatedIdentifiers = (userInfo["updated"] as? [PersistentIdentifier]) ?? []
            
            let ds = DataService(modelContext: modelContext)
            let context = modelContext
            
            let insertedObjects = insertedIdentifiers.compactMap { identifier in
                context.model(for: identifier)
            }
            
            let updatedObjects = updatedIdentifiers.compactMap { identifier in
                context.model(for: identifier)
            }
            
            let deletedObjects = deletedIdentifiers.map { identifier in
                identifier
            }
            
            //                print("Inserted objects: \(insertedObjects)")
            //                print("Updated objects: \(updatedObjects)")
            //                print("Deleted identifiers: \(deletedObjects)")
            
            ds.updateMangaSettings(for: updatedObjects)
        }
    }
}


#Preview {
    RootView()
}
