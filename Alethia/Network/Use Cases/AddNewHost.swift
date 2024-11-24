//
//  AddNewHost.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/11/2024.
//

import Foundation

func getNewHost(for url: String) async throws -> TransientHost {
    let ns = NetworkService()
    
    guard let rootUrl = URL.appendingPaths(url) else {
        throw NetworkError.missingURL
    }
    
    let host: HostDTO = try await ns.request(url: rootUrl)
    
    var sources = [SourceExtendedDTO]()
    
    for source in host.sources {
        guard let sourceUrl = URL.appendingPaths(rootUrl.absoluteString, "api", "v\(host.version)", source.path),
              let iconPath = URL.appendingPaths(rootUrl.absoluteString, "icons", "\(source.path).png")
        else {
            throw NetworkError.missingURL
        }
        
        let sourceDTO: SourceDTO = try await ns.request(url: sourceUrl)
        
        print("Source: \(source.source)")
        print("Icon: \(iconPath.absoluteString)")
        print("------------------------")
        sourceDTO.routes.forEach {
            print($0.name)
        }
        print("\n\n\n")
        
        sources.append(SourceExtendedDTO(sourceDTO: sourceDTO, name: source.source, icon: iconPath.absoluteString, path: source.path))
    }
    
    return TransientHost(host: host, sources: sources)
}
