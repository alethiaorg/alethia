//
//  Collection.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/11/2024.
//

import Foundation
import SwiftData

@Model
final class Collection {
    // MARK: Definitions - Unique Definitions
    #Unique<Collection>([\.name])
    
    // MARK: Properties
    
    var id = UUID()
    @Attribute(.unique) var name: String
    
    // MARK: Relational Properties
    
    @Relationship(deleteRule: .nullify, inverse: \Manga.collections) var mangas: [Manga] = []
    
    // MARK: Transient (Computed) Properties
    
    @Transient
    var size: Int {
        mangas.filter { $0.inLibrary }.count
    }
    
    // MARK: Initializer
    
    init(name: String) {
        self.name = name
    }
}
