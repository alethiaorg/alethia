//
//  Source.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/11/2024.
//

import Foundation
import SwiftData

@Model
final class Source {
    // MARK: Properties
    
    var id: UUID
    var name: String
    var icon: String
    var path: String
    
    // MARK: App-related Properties
    
    var pinned: Bool = false
    
    // MARK: Relational Properties
    
    @Relationship(deleteRule: .cascade, inverse: \Host.sources) var host: Host?
    var origins: [Origin] = [Origin]()
    var routes: [SourceRoute] = [SourceRoute]()
    
    // MARK: Initializer
    
    init(id: UUID, name: String, icon: String, path: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.path = path
    }
}

@Model
final class SourceRoute {
    // MARK: Properties
    
    var name: String
    var path: String
    
    // MARK: Relational Properties
    
    @Relationship(inverse: \Source.routes) var source: Source?
    
    // MARK: Initializer
    
    init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}
