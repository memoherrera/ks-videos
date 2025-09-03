//
//  VideosAPIError.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Foundation

public enum VideosAPIError: Error, LocalizedError {
    case badURL
    case transport(URLError)        // network layer error
    case decoding(Error)            // JSON decode failed
    case serverResponse             // non-2xx

    public var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid videos URL."
        case .transport(let e): return e.localizedDescription
        case .decoding: return "Failed to decode videos response."
        case .serverResponse: return "Unexpected server response."
        }
    }
}
