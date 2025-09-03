//
//  VideosAPITests.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera on 02/09/25.
//


// VideosAPITests.swift
import XCTest
@testable import KSVIdeos

final class VideosAPITests: XCTestCase {

    // Helper
    private func makeItem(_ id: String = "v1") -> VideoItemDTO {
        VideoItemDTO(
            id: id,
            title: "Title \(id)",
            thumbnailUrl: "https://example.com/\(id).jpg",
            duration: "10:00",
            uploadTime: "2025-01-01T00:00:00Z",
            views: "1000",
            author: "Author",
            videoUrl: "https://example.com/\(id).mp4",
            description: "Desc",
            subscriber: "Chan",
            isLive: false
        )
    }

    // MARK: - Tests

    func test_fetchVideos_success_returnsItems_andCallsCorrectPath() async throws {
        let mock = MockHttpClient()
        let expected = [
            VideoItemDTO(id:"a", title:"A", thumbnailUrl:"t", duration:"d", uploadTime:"u", views:"v", author:"au", videoUrl:"vu", description:"desc", subscriber:"s", isLive:false),
            VideoItemDTO(id:"b", title:"B", thumbnailUrl:"t", duration:"d", uploadTime:"u", views:"v", author:"au", videoUrl:"vu", description:"desc", subscriber:"s", isLive:false),
        ]
        mock.listStub = .success(expected)

        let api = VideosAPI(client: mock)
        let result = try await api.fetchVideos()

        XCTAssertEqual(result, expected)
        XCTAssertEqual(mock.lastPathList, VideosEndpoint.list.path) // "videos.json"
    }

    func test_fetchVideos_mapsURLError_toTransport() async {
        let mock = MockHttpClient()
        mock.listStub = .failure(URLError(.timedOut))
        let api = VideosAPI(client: mock)

        do {
            _ = try await api.fetchVideos()
            XCTFail("Expected to throw")
        } catch let err as VideosAPIError {
            guard case .transport(let urlErr) = err else { return XCTFail("Expected .transport") }
            XCTAssertEqual(urlErr.code, .timedOut)
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func test_fetchVideos_mapsDecodingError_toDecoding() async {
        let mock = MockHttpClient()
        let decErr = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "broken"))
        mock.listStub = .failure(decErr)
        let api = VideosAPI(client: mock)

        do { _ = try await api.fetchVideos(); XCTFail("Expected error") }
        catch let err as VideosAPIError {
            guard case .decoding = err else { return XCTFail("Expected .decoding") }
        } catch { XCTFail("Wrong error: \(error)") }
    }

    func test_fetchVideos_rethrowsOtherErrors() async {
        struct Dummy: Error {}
        let mock = MockHttpClient()
        mock.listStub = .failure(Dummy())
        let api = VideosAPI(client: mock)

        do { _ = try await api.fetchVideos(); XCTFail("Expected error") }
        catch { XCTAssertTrue(error is Dummy) }
    }
}

