//
//  VideosEndpoint.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera

enum VideosEndpoint {
    case list

    var path: String {
        switch self {
        case .list: return "videos.json"
        }
    }

    var queryItems: [String: String]? { nil }
}
