//
//  Video.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Foundation

public struct Video: Sendable, Equatable, Hashable, Identifiable {
    public let id: String
    public let title: String
    public let thumbnailURL: URL
    public let durationSeconds: Int
    public let uploadDate: Date
    public let viewCount: Int
    public let author: String
    public let videoURL: URL
    public let description: String
    public let subscriberCount: Int?
    public let isLive: Bool
}
