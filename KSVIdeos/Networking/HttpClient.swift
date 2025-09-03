//
//  HttpClient.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Foundation

final class HttpClient: HttpClientProtocol {
    
    let baseURL: URL
    let session: URLSession
    
    init(baseURL: URL, session: URLSession? = nil) {
        self.baseURL = baseURL
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 20.0
            configuration.timeoutIntervalForResource = 20.0
            configuration.waitsForConnectivity = true
            self.session = URLSession(configuration: configuration)
        }
    }
    
    func buildURLfrom(_ path: String, queryItems: [String: String]? = nil) -> URL? {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        
        // Append query items if provided
        if let queryItems = queryItems {
            urlComponents?.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents?.url else {
            print("❌ Invalid URL Components:", urlComponents as Any)
            return nil
        }
        
        return url
    }
    
    /// Generic GET function to fetch and decode a resource.
    func get<T: Decodable>(_ path: String, queryItems: [String: String]? = nil) async throws -> T {
        // Get final URL
        guard let url = buildURLfrom(path, queryItems: queryItems) else {
            throw URLError(.badURL)
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Perform request
        let (data, response) = try await session.data(for: request)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Decode and return
        let decodedObject = try JSONDecoder().decode(T.self, from: data)
        return decodedObject
    }
    
    func getList<T: Decodable>(_ path: String) async throws -> [T] {
        
        let url = self.baseURL.appendingPathComponent(path)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
                (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode([T].self, from: data)
        return decoded
    }
}
