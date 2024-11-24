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
    @Relationship(deleteRule: .cascade, inverse: \Host.sources) var host: Host?
    
    var id: UUID
    var name: String
    var icon: String
    var path: String
    
    // App-related
    var pinned: Bool = false
    
    var origins: [Origin] = [Origin]()
    var routes: [SourceRoute] = [SourceRoute]()
    
    init(id: UUID, name: String, icon: String, path: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.path = path
    }
}

@Model
final class SourceRoute {
    @Relationship(inverse: \Source.routes) var source: Source?
    
    var name: String
    var path: String
    
    init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}
