//
//  VideoDetailViewModelTests.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import XCTest
import Combine
import AVFoundation
@testable import KSVIdeos

@MainActor
final class VideoDetailViewModelTests: XCTestCase {
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Mocks

    final class MockDownloadManager: DownloadManagerProtocol, @unchecked Sendable {
        private let subject = PassthroughSubject<DownloadEvent, Never>()
        var events: AnyPublisher<DownloadEvent, Never> { subject.eraseToAnyPublisher() }

        // inspectable
        private(set) var started: [(id: String, url: URL)] = []
        private(set) var cancelled: [String] = []
        var isDownloadingReturn = false
        var startError: Error? = nil

        func startDownload(id: String, from url: URL) throws {
            if let e = startError { throw e }
            started.append((id, url))
        }
        func cancelDownload(id: String) { cancelled.append(id) }
        func isDownloading(id: String) -> Bool { isDownloadingReturn }

        // helpers to fire events
        func send(_ event: DownloadEvent) { subject.send(event) }
    }

    final class MockDownloadsRepository: DownloadsRepository, @unchecked Sendable {
        var isDownloadedLocallyReturn: Result<Bool, Error> = .success(false)
        
        func isDownloadedLocally(videoId: String) throws -> Bool {
            switch isDownloadedLocallyReturn {
            case .success(let v): return v
            case .failure(let e): throw e
            }
        }
        
        func fetchAll() throws -> [KSVIdeos.DownloadedVideoUI] {
            throw XCTestError(_nsError: NSError(domain: "", code: -1, userInfo: nil))
        }
        
        func delete(videoId: String) throws {
            throw XCTestError(_nsError: NSError(domain: "", code: -1, userInfo: nil))
        }
        
        var existsReturn: Result<Bool, Error> = .success(false)
        private(set) var saved: [DownloadRecord] = []
        var saveError: Error? = nil

        func exists(videoId: String) throws -> Bool {
            switch existsReturn {
            case .success(let v): return v
            case .failure(let e): throw e
            }
        }

        func save(record: DownloadRecord) throws {
            if let e = saveError { throw e }
            saved.append(record)
        }
    }

    // MARK: - Helpers

    private func makeItem(
        id: String = "vid-1",
        title: String = "Sample",
        playURL: URL = URL(string: "https://example.com/video.mp4")!
    ) -> VideoItemUI {
        VideoItemUI(
            id: id,
            title: title,
            thumbnailURL: URL(string: "https://example.com/thumb.jpg")!,
            playURL: playURL,
            descriptionText: "Some description",
            durationText: "1:00",
            uploadDateText: "Jan 1, 2025",
            viewsText: "1,234",
            author: "Author",
            isLive: false
        )
    }

    // MARK: - Tests

    func test_init_setsIsDownloadedFromRepository() {
        let dm = MockDownloadManager()
        let repo = MockDownloadsRepository()
        repo.isDownloadedLocallyReturn = .success(true)

        let vm = VideoDetailViewModel(item: makeItem(), downloadManager: dm, downloadsRepository: repo)

        XCTAssertTrue(vm.isDownloaded)
        XCTAssertFalse(vm.isDownloading)
        XCTAssertNil(vm.downloadErrorMessage)
    }

    func test_startDownload_starts_whenNotDownloadedAndNotDownloading() {
        let dm = MockDownloadManager()
        let repo = MockDownloadsRepository()
        repo.existsReturn = .success(false)

        let item = makeItem()
        let vm = VideoDetailViewModel(item: item, downloadManager: dm, downloadsRepository: repo)

        vm.startDownload()

        XCTAssertEqual(dm.started.count, 1)
        XCTAssertEqual(dm.started.first?.id, item.id)
        XCTAssertEqual(dm.started.first?.url, item.playURL)
        XCTAssertTrue(vm.isDownloading)
        XCTAssertEqual(vm.downloadProgress, 0, accuracy: .ulpOfOne)
        XCTAssertNil(vm.downloadErrorMessage)
    }

    func test_startDownload_guard_skips_whenAlreadyDownloadingOrDownloaded() {
        // case A: already downloaded
        do {
            let dm = MockDownloadManager()
            let repo = MockDownloadsRepository()
            repo.isDownloadedLocallyReturn = .success(true) // init sets isDownloaded = true
            let vm = VideoDetailViewModel(item: makeItem(), downloadManager: dm, downloadsRepository: repo)
            vm.startDownload()
            XCTAssertTrue(vm.isDownloaded)
            XCTAssertTrue(dm.started.isEmpty)
        }

        // case B: manager says "already downloading"
        do {
            let dm = MockDownloadManager()
            dm.isDownloadingReturn = true
            let repo = MockDownloadsRepository()
            repo.existsReturn = .success(false)
            let vm = VideoDetailViewModel(item: makeItem(), downloadManager: dm, downloadsRepository: repo)
            vm.startDownload()
            XCTAssertTrue(dm.started.isEmpty)
            XCTAssertFalse(vm.isDownloading) // guard prevents us from toggling
        }
    }

    func test_events_progress_updatesState() {
        let dm = MockDownloadManager()
        let repo = MockDownloadsRepository()
        repo.existsReturn = .success(false)

        let item = makeItem()
        let vm = VideoDetailViewModel(item: item, downloadManager: dm, downloadsRepository: repo)

        vm.startDownload()

        let progressExp = expect(
            "progress==0.4",
            from: vm.$downloadProgress.dropFirst(),
            where: { abs($0 - 0.4) < 0.0001 },
            storeIn: &cancellables
        )

        dm.send(.progress(id: item.id, fraction: 0.4))
        wait(for: [progressExp], timeout: 2.0)

        XCTAssertTrue(vm.isDownloading)
        XCTAssertEqual(vm.downloadProgress, 0.4, accuracy: 0.0001)
    }

    func test_events_finished_marksDownloaded_andSavesRecord() {
        let dm = MockDownloadManager()
        let repo = MockDownloadsRepository()
        repo.existsReturn = .success(false)

        let item = makeItem()
        let vm = VideoDetailViewModel(item: item, downloadManager: dm, downloadsRepository: repo)

        vm.startDownload()

        // Expect progress to reach 1.0 (the VM sets it on .finished)
        let finishedExp = expect(
            "progress==1.0",
            from: vm.$downloadProgress.dropFirst(),
            where: { abs($0 - 1.0) < 0.0001 },
            storeIn: &cancellables
        )

        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try? Data([0x00, 0x01]).write(to: tmp)

        dm.send(.finished(id: item.id, fileURL: tmp, bytes: 2))

        wait(for: [finishedExp], timeout: 1.0)

        XCTAssertTrue(vm.isDownloaded)
        XCTAssertFalse(vm.isDownloading)
        XCTAssertEqual(repo.saved.count, 1)
        XCTAssertEqual(repo.saved.first?.videoId, item.id)
        XCTAssertEqual(repo.saved.first?.fileSize, 2)
        XCTAssertEqual(repo.saved.first?.localPath, tmp.path)
    }

    func test_events_failed_setsError_andResetsProgress() {
        let dm = MockDownloadManager()
        let repo = MockDownloadsRepository()
        repo.existsReturn = .success(false)
        let item = makeItem()
        let vm = VideoDetailViewModel(item: item, downloadManager: dm, downloadsRepository: repo)

        vm.startDownload()

        // Expect progress to become 0.0 after failure (it’s set in .failed handler)
        let resetExp = expect(
            "progress==0.0",
            from: vm.$downloadProgress.dropFirst(),
            where: { abs($0 - 0.0) < 0.0001 },
            storeIn: &cancellables
        )

        dm.send(.progress(id: item.id, fraction: 0.5))
        dm.send(.failed(id: item.id, error: URLError(.cannotConnectToHost)))

        wait(for: [resetExp], timeout: 1.0)

        XCTAssertFalse(vm.isDownloading)
        XCTAssertNotNil(vm.downloadErrorMessage)
    }

    func test_cancelDownload_forwardsToManager() {
        let dm = MockDownloadManager()
        let repo = MockDownloadsRepository()
        let item = makeItem()
        let vm = VideoDetailViewModel(item: item, downloadManager: dm, downloadsRepository: repo)

        vm.cancelDownload()
        XCTAssertEqual(dm.cancelled, [item.id])
    }

    func test_playbackEndNotification_resetsFlags_andHidesPlayer() {
        let dm = MockDownloadManager()
        let repo = MockDownloadsRepository()
        let vm = VideoDetailViewModel(item: makeItem(), downloadManager: dm, downloadsRepository: repo)

        // Put the VM in "playing" mode in the simplest way we control
        vm.startPlayback()
        XCTAssertTrue(vm.showPlayer)

        // Post end-of-playback for the current item
        guard let item = vm.player.currentItem else {
            // If for some reason the player has no item, we can't test notifications
            XCTFail("Player item missing")
            return
        }
        NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: item)

        // Allow main queue to process
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))

        XCTAssertFalse(vm.showPlayer)
        XCTAssertFalse(vm.isPlaying)
    }

    func test_playbackFailedNotification_setsError_andStops() {
        let dm = MockDownloadManager()
        let repo = MockDownloadsRepository()
        let vm = VideoDetailViewModel(item: makeItem(), downloadManager: dm, downloadsRepository: repo)

        guard let item = vm.player.currentItem else {
            XCTFail("Player item missing")
            return
        }

        let nsError = NSError(domain: "test", code: -1, userInfo: nil)
        NotificationCenter.default.post(
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            userInfo: [AVPlayerItemFailedToPlayToEndTimeErrorKey: nsError]
        )

        RunLoop.main.run(until: Date().addingTimeInterval(0.01))

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isPlaying)
    }
    
    // Helpers
    private func expect<T>(
      _ description: String,
      from publisher: some Publisher<T, Never>,
      where predicate: @escaping (T) -> Bool,
      timeout: TimeInterval = 2.0,
      storeIn bag: inout Set<AnyCancellable>
    ) -> XCTestExpectation {
      let exp = XCTestExpectation(description: description)
      publisher
        .sink { value in
          if predicate(value) { exp.fulfill() }
        }
        .store(in: &bag)                                     // <-- retain
      return exp
    }
}
