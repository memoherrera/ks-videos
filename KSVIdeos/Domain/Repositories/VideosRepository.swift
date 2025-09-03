//
//  VideosRepository.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

public protocol VideosRepository {
    /// Returns domain videos (already adapted from DTOs).
    func getVideos() async throws -> [Video]
}
