//
//  VideosRepositoryImpl.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Foundation

public final class VideosRepositoryImpl: VideosRepository {
    private let api: VideosAPIProtocol
    private let adapter: VideoAdapter

    public init(api: VideosAPIProtocol, adapter: VideoAdapter = .init()) {
        self.api = api
        self.adapter = adapter
    }

    public func getVideos() async throws -> [Video] {
        do {
            let dtos = try await api.fetchVideos()
            return try dtos.map(adapter.map(_:))
        } catch let apiError as VideosAPIError {
            // Map infra errors to domain-facing errors
            switch apiError {
            case .transport(let urlErr): throw VideosRepositoryError.network(urlErr)
            case .decoding(let decErr):  throw VideosRepositoryError.decoding(decErr as! DecodingError)
            case .serverResponse:        throw VideosRepositoryError.server
            case .badURL:                throw VideosRepositoryError.unknown("Bad videos URL.")
            }
        } catch let mapErr as VideoMappingError {
            throw VideosRepositoryError.mapping(mapErr)
        } catch let decErr as DecodingError {
            throw VideosRepositoryError.decoding(decErr)
        } catch let urlErr as URLError {
            throw VideosRepositoryError.network(urlErr)
        } catch {
            throw VideosRepositoryError.unknown(error.localizedDescription)
        }
    }
}
