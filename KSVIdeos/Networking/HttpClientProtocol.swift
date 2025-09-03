//
//  HttpClientProtocol.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

public protocol HttpClientProtocol: Sendable {
    func get<T: Decodable>(_ path: String, queryItems: [String: String]?) async throws -> T
    func getList<T: Decodable>(_ path: String) async throws -> [T]
}
