//
//  Host.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/11/2024.
//

import Foundation
import SwiftData

@Model
final class Host {
    // MARK: Definitions - Unique Definitions
    #Unique<Host>([\.id], [\.name], [\.baseUrl])
    
    // MARK: Properties
    
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    @Attribute(.unique) var baseUrl: String
    var version: Int
    
    // MARK: Relational Properties
    
    var sources: [Source] = [Source]()
    
    // MARK: Initializer
    
    init(id: UUID, name: String, baseUrl: String, version: Int) {
        self.id = id
        self.name = name
        self.baseUrl = baseUrl
        self.version = version
    }
}
