//
//  VideosAPIProtocol.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera on 01/09/25.
//

import Foundation

public protocol VideosAPIProtocol {
    func fetchVideos() async throws -> [VideoItemDTO]
}
