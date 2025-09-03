//
//  VideosAPI.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Foundation

final class VideosAPI: VideosAPIProtocol {

    private let client: HttpClientProtocol

    public init(client: HttpClientProtocol) {
        self.client = client
    }

    /// Fetches a list of VideoItemDTO from the backend.
    public func fetchVideos() async throws -> [VideoItemDTO] {
        do {
            return try await client.getList(VideosEndpoint.list.path)
        } catch let urlError as URLError {
            throw VideosAPIError.transport(urlError)
        } catch let decodingError as DecodingError {
            throw VideosAPIError.decoding(decodingError)
        } catch {
            throw error
        }
    }
}
