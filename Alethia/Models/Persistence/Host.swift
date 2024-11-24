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
    #Unique<Host>([\.id], [\.name], [\.baseUrl])
    
    var id: UUID
    var name: String
    var baseUrl: String
    var version: Int
    var sources: [Source] = [Source]()
    
    init(id: UUID, name: String, baseUrl: String, version: Int) {
        self.id = id
        self.name = name
        self.baseUrl = baseUrl
        self.version = version
    }
}
