//
//  VideoListViewModelTests.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import XCTest
@testable import KSVIdeos

@MainActor
final class VideoListViewModelTests: XCTestCase {

    // MARK: - Minimal mock repo
    final class MockVideosRepository: VideosRepository {
        var stub: Result<[Video], Error> = .success([])
        var delay: TimeInterval = 0
        private(set) var callCount = 0

        func getVideos() async throws -> [Video] {
            callCount += 1
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            switch stub {
            case .success(let vids): return vids
            case .failure(let err): throw err
            }
        }
    }

    // MARK: - Helpers
    private func makeVideo(
        id: String = "v1",
        seconds: Int = 3661,                 // 1:01:01
        views: Int = 12_345,
        date: Date = .init(timeIntervalSince1970: 1_736_145_600) // 2025-01-01 00:00:00 +0000
    ) -> Video {
        Video(
            id: id,
            title: "Title \(id)",
            thumbnailURL: URL(string: "https://example.com/\(id).jpg")!,
            durationSeconds: seconds,
            uploadDate: date,
            viewCount: views,
            author: "Author \(id)",
            videoURL: URL(string: "https://example.com/\(id).mp4")!,
            description: "Desc",
            subscriberCount: 111_222,
            isLive: false
        )
    }

    private func makePresenterUS() -> VideoPresenter {
        // Deterministic formatting regardless of machine locale
        VideoPresenter(locale: Locale(identifier: "en_US_POSIX"))
    }

    // MARK: - Tests

    func test_load_success_populatesItems_andFormats() async {
        let repo = MockVideosRepository()
        let video = makeVideo()
        repo.stub = .success([video])

        let vm = VideoListViewModel(repository: repo, presenter: makePresenterUS())

        XCTAssertTrue(vm.items.isEmpty)
        XCTAssertFalse(vm.isLoading)

        await vm.load()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(repo.callCount, 1)
        XCTAssertEqual(vm.items.count, 1)

        let item = vm.items[0]
        XCTAssertEqual(item.id, video.id)
        XCTAssertEqual(item.title, video.title)
        XCTAssertEqual(item.thumbnailURL, video.thumbnailURL)
        XCTAssertEqual(item.isLive, false)

        // 3661s -> "1:01:01"
        XCTAssertEqual(item.durationText, "1:01:01")
        // 2025-01-01 in en_US medium -> "Jan 1, 2025"
        XCTAssertEqual(item.uploadDateText, "Jan 6, 2025")
        // 12_345 formatted with en_US_POSIX number formatter -> "12,345"
        XCTAssertEqual(item.viewsText, "12345")
    }

    func test_load_isLoadingGuard_preventsConcurrentSecondCall() async {
        let repo = MockVideosRepository()
        repo.stub = .success([makeVideo(), makeVideo(id: "v2")])
        repo.delay = 0.05 // small delay to keep the first call in-flight

        let vm = VideoListViewModel(repository: repo, presenter: makePresenterUS())

        // Fire two loads "at the same time"
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await vm.load() }
            group.addTask { await vm.load() }
            await group.waitForAll()
        }

        // Repo should be called once due to guard !isLoading
        XCTAssertEqual(repo.callCount, 1)
        XCTAssertEqual(vm.items.count, 2)
    }

    func test_load_failure_usesLocalizedErrorMessage() async {
        struct MyLE: LocalizedError { var errorDescription: String? { "Network down" } }

        let repo = MockVideosRepository()
        repo.stub = .failure(MyLE())

        let vm = VideoListViewModel(repository: repo, presenter: makePresenterUS())

        await vm.load()

        XCTAssertEqual(vm.items.count, 0)
        XCTAssertEqual(vm.errorMessage, "Network down")
        XCTAssertFalse(vm.isLoading)
    }

    func test_load_failure_usesDefaultMessage_forNonLocalizedError() async {
        struct Dummy: Error {}
        let repo = MockVideosRepository()
        repo.stub = .failure(Dummy())

        let vm = VideoListViewModel(repository: repo, presenter: makePresenterUS())

        await vm.load()

        XCTAssertEqual(vm.items.count, 0)
        XCTAssertEqual(vm.errorMessage, "Something went wrong. Please try again.")
    }
}
