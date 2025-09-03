//
//  VideosRepositoryError.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//
import Foundation

public enum VideosRepositoryError: Error, LocalizedError, Equatable {
    case network(URLError)
    case decoding(DecodingError)
    case mapping(VideoMappingError)
    case server
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .network(let e):   return e.localizedDescription
        case .decoding:         return "Failed to decode server response."
        case .mapping(let e):   return e.localizedDescription
        case .server:           return "Unexpected server response."
        case .unknown(let msg): return msg
        }
    }

    public static func == (lhs: VideosRepositoryError, rhs: VideosRepositoryError) -> Bool {
        switch (lhs, rhs) {
        case (.server, .server): return true
        case (.unknown, .unknown): return true
        case (.decoding, .decoding): return true
        case (.mapping(let a), .mapping(let b)): return a.localizedDescription == b.localizedDescription
        case (.network(let a), .network(let b)): return a.code == b.code
        default: return false
        }
    }
}
