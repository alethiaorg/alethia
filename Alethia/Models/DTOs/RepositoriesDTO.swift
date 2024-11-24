//
//  HostDTO.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/11/2024.
//

import Foundation

// Check '/'
struct HostDTO: Codable {
    let repository: String
    let version: Int
    let sources: [HostSourceDTO]
}

struct HostSourceDTO: Codable {
    let source: String
    let path: String
}

// Check '/api/v{version}/{source_path}'
struct SourceDTO: Codable {
    let routes: [RouteDTO]
}

struct RouteDTO: Codable {
    let path: String
    let name: String
}

// To include icon
struct SourceExtendedDTO: Codable {
    var id = UUID()
    
    let name: String
    let icon: String
    let path: String
    let routes: [RouteDTO]
    
    
    init(sourceDTO: SourceDTO, name: String, icon: String, path: String) {
        self.name = name
        self.icon = icon
        self.path = path
        self.routes = sourceDTO.routes
    }
}

// Wrapper struct
struct TransientHost {
    let host: HostDTO
    let sources: [SourceExtendedDTO]
}
