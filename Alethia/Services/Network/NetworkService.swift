//
//  NetworkService.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/11/2024.
//

import Foundation

final class NetworkService {
    
    private let decoder: JSONDecoder
    
    init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = NetworkService.dateFormatter()
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
        }
    }
    
    func request<Model: Decodable>(url: URL) async throws -> Model {
        let (data, response) = try await makeRequest(url: url)
        try handleResponse(response)
        
        do {
            let model = try decoder.decode(Model.self, from: data)
            return model
        } catch {
            print("Decoding Error: \(error)")
            print("Data: \(String(data: data, encoding: .utf8) ?? "No Data")")
            throw error
        }
    }
}


// MARK - Extensions

extension NetworkService {
    func makeRequest(url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return try await URLSession.shared.data(for: request)
    }
    
    func handleResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
    
    static func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }
}

