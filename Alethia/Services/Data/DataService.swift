//
//  DataService.swift
//  Alethia
//
//  Created by Angelo Carasig on 30/11/2024.
//

import Foundation
import SwiftData

final class DataService {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func updateMangaSettings(for objects: [Any]) -> Void {
        let manga: [Manga] = objects.compactMap {
            $0 as? Manga
        }
        
        do {
            var hasChanges = false
            for entry in manga {
                if entry.needsSettingsUpdate {
                    entry.originsDidChange()
                    hasChanges = true
                }
                
                // Set each entry to false
                entry.needsSettingsUpdate = false
            }
            
            if hasChanges {
                try modelContext.save()
            }
        }
        catch {
            print("Model Context failed to save.")
        }
    }
}
