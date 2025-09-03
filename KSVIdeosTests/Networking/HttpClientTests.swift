//
//  HttpClientTests.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import XCTest
@testable import KSVIdeos

final class HttpClientTests: XCTestCase {

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
    
    // Test struct
    struct Movie: Codable, Equatable {
        let id: Int
        let title: String
    }

    let baseURL = URL(string: "https://api.example.com")!

    // 1) URL building
    func test_buildURLfrom_withoutQueryItems() {
        let client = HttpClient(baseURL: baseURL, session: makeSession())
        let url = client.buildURLfrom("movies/top")
        XCTAssertEqual(url?.absoluteString, "https://api.example.com/movies/top")
    }

    func test_buildURLfrom_withQueryItems_percentEncodes() {
        let client = HttpClient(baseURL: baseURL, session: makeSession())
        let url = client.buildURLfrom("search", queryItems: [
            "q": "the godfather",
            "page": "2",
            "lang": "en-US"
        ])
        // Order of query items is not guaranteed; assert components instead.
        let comps = URLComponents(url: url!, resolvingAgainstBaseURL: false)!
        XCTAssertEqual(comps.path, "/search")
        let items = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(items["q"], "the godfather")
        XCTAssertEqual(items["page"], "2")
        XCTAssertEqual(items["lang"], "en-US")
    }

    // 2) GET success
    func test_get_decodesOn200() async throws {
        let session = makeSession()
        let client = HttpClient(baseURL: baseURL, session: session)

        let movie = Movie(id: 1, title: "KSVideos")
        let data = try JSONEncoder().encode(movie)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/movies/1")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let result: Movie = try await client.get("movies/1")
        XCTAssertEqual(result, movie)
    }

    // 3) Non-2xx -> badServerResponse
    func test_get_throwsOnNon2xx() async {
        let session = makeSession()
        let client = HttpClient(baseURL: baseURL, session: session)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data("{}".utf8))
        }

        do {
            let _: Movie = try await client.get("movies/1")
            XCTFail("Expected error")
        } catch {
            guard let urlError = error as? URLError else { return XCTFail("Wrong error type") }
            XCTAssertEqual(urlError.code, .badServerResponse)
        }
    }

    // 4) getList decodes arrays
    func test_getList_decodesArrayOn200() async throws {
        let session = makeSession()
        let client = HttpClient(baseURL: baseURL, session: session)

        let mock = [Movie(id: 1, title: "A"), Movie(id: 2, title: "B")]
        let data = try JSONEncoder().encode(mock)

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/movies")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let list: [Movie] = try await client.getList("movies")
        XCTAssertEqual(list, mock)
    }
}
