//
//  VideoItemDTO.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

// MARK: - DTOs (API contracts only)
public struct VideoItemDTO: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let thumbnailUrl: String
    public let duration: String
    public let uploadTime: String
    public let views: String
    public let author: String
    public let videoUrl: String
    public let description: String
    public let subscriber: String
    public let isLive: Bool
}

public typealias VideoListDTO = [VideoItemDTO]
