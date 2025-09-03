//
//  MockHttpClient.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import XCTest
@testable import KSVIdeos

final class MockHttpClient: HttpClientProtocol, @unchecked Sendable {
    var lastPathList: String?
    var lastPathGet: String?
    var listStub: Result<[VideoItemDTO], Error> = .success([])
    var getStubData: Result<Data, Error>? = nil

    // Only the method we need; keep it generic but handle VideoItemDTO only.
    func getList<T: Decodable>(_ path: String) async throws -> [T] {
        lastPathList = path
        switch listStub {
        case .success(let items):
            if T.self == VideoItemDTO.self {
                // Cast is safe in tests because we only use [VideoItemDTO]
                return items as! [T]
            } else {
                // For completeness, re-encode+decode if someone asks for another T
                let data = try JSONEncoder().encode(items)
                return try JSONDecoder().decode([T].self, from: data)
            }
        case .failure(let error):
            throw error
        }
    }
    
    func get<T: Decodable>(_ path: String, queryItems: [String : String]? = nil) async throws -> T {
        lastPathGet = path
        guard let getStubData else { throw URLError(.unsupportedURL) }
        switch getStubData {
        case .success(let data):
            return try JSONDecoder().decode(T.self, from: data)
        case .failure(let error):
            throw error
        }
    }
}
