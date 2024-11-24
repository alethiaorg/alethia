//
//  NetworkError.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/11/2024.
//

import Foundation

enum NetworkError: Error {
    case missingURL
    case noConnect
    case invalidData
    case requestFailed
    case encodingError
    case decodingError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .missingURL:
            return "An Invalid URL was provided."
        case .noConnect:
            return "No connection."
        case .invalidResponse:
            return "An invalid response was received from server."
        case .invalidData:
            return "Invalid data received."
        case .decodingError:
            return "Failed to decode data received."
        case .encodingError:
            return "Failed to encode data received."
        case .requestFailed:
            return "Network request failed."
        }
    }
}
