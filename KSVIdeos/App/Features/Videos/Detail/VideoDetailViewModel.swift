//
//  VideoDetailViewModel.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import AVKit
import Combine

import AVKit
import Combine

final class VideoDetailViewModel: ObservableObject {
    // Input is UI model, not domain
    let item: VideoItemUI

    // Player
    let player: AVPlayer

    // Download infra
    private let downloadManager: DownloadManagerProtocol
    private let downloadsRepository: DownloadsRepository

    // Public UI state
    @Published var showPlayer = false
    @Published private(set) var isPlaying = false
    @Published private(set) var isBuffering = false
    @Published private(set) var errorMessage: String?

    // Download state
    @Published private(set) var isDownloaded = false
    @Published private(set) var isDownloading = false
    @Published private(set) var downloadProgress: Double = 0.0
    @Published private(set) var downloadErrorMessage: String?

    // Internal
    private var cancellables = Set<AnyCancellable>()
    private var kvoTokens: [NSKeyValueObservation] = []
    private var notifObservers: [NSObjectProtocol] = []

    init(item: VideoItemUI,
         downloadManager: DownloadManagerProtocol,
         downloadsRepository: DownloadsRepository) {

        self.item = item
        self.player = AVPlayer(url: item.playURL)
        self.downloadManager = downloadManager
        self.downloadsRepository = downloadsRepository

        if let it = player.currentItem { attachObservers(for: it) }

        let timeControlKVO = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isPlaying = (player.timeControlStatus == .playing)
                if let it = self.player.currentItem { self.updateBufferingState(for: it) }
            }
        }
        kvoTokens.append(timeControlKVO)

        let rateKVO = player.observe(\.rate, options: [.new, .initial]) { [weak self] player, _ in
            DispatchQueue.main.async { self?.isPlaying = player.rate > 0 }
        }
        kvoTokens.append(rateKVO)

        do {
            self.isDownloaded = try downloadsRepository.isDownloadedLocally(videoId: item.id)
        }
        catch {
            self.downloadErrorMessage = "Failed checking downloads: \(error.localizedDescription)"
        }

        downloadManager.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case let .progress(id, fraction) where id == self.item.id:
                    self.isDownloading = true
                    self.downloadProgress = fraction
                case let .finished(id, fileURL, bytes) where id == self.item.id:
                    self.isDownloading = false
                    self.downloadProgress = 1.0
                    self.persistDownloadedFile(fileURL: fileURL, bytes: bytes)
                case let .failed(id, error) where id == self.item.id:
                    self.isDownloading = false
                    self.downloadProgress = 0.0
                    self.downloadErrorMessage = error.localizedDescription
                default: break
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    func startPlayback() {
        showPlayer = true
        player.play()
    }

    @MainActor
    func pause() {
        player.pause()
        isPlaying = false
    }

    private func attachObservers(for item: AVPlayerItem) {
        let end = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.isPlaying = false
            self.isBuffering = false
            self.player.seek(to: .zero)
            self.showPlayer = false
        }
        notifObservers.append(end)

        let failed = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main
        ) { [weak self] note in
            guard let self else { return }
            let nsError = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError
            self.errorMessage = nsError?.localizedDescription ?? "Failed to play."
            self.isBuffering = false
            self.isPlaying = false
        }
        notifObservers.append(failed)

        item.publisher(for: \.status, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak item] status in
                guard let self, let item else { return }
                if status == .failed {
                    self.errorMessage = item.error?.localizedDescription ?? "Playback failed."
                }
                self.updateBufferingState(for: item)
            }
            .store(in: &cancellables)

        let emptyPub = item.publisher(for: \.isPlaybackBufferEmpty, options: [.initial, .new])
        let keepUpPub = item.publisher(for: \.isPlaybackLikelyToKeepUp, options: [.initial, .new])

        emptyPub
            .merge(with: keepUpPub.map { _ in true })
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak item] _ in
                guard let self, let item else { return }
                self.updateBufferingState(for: item)
            }
            .store(in: &cancellables)
    }

    private func updateBufferingState(for item: AVPlayerItem) {
        let waiting = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
        let empty = item.isPlaybackBufferEmpty
        let notKeepUp = !item.isPlaybackLikelyToKeepUp
        isBuffering = waiting || (empty && notKeepUp)
    }

    // Downloads
    func startDownload() {
        guard !isDownloaded, !downloadManager.isDownloading(id: item.id) else { return }
        do {
            try downloadManager.startDownload(id: item.id, from: item.playURL)
            isDownloading = true
            downloadProgress = 0
            downloadErrorMessage = nil
        } catch {
            downloadErrorMessage = error.localizedDescription
        }
    }

    func cancelDownload() {
        downloadManager.cancelDownload(id: item.id)
    }

    private func persistDownloadedFile(fileURL: URL, bytes: Int64) {
        do {
            let record = DownloadRecord(
                videoId: item.id,
                title: item.title,
                localPath: fileURL.path,
                fileSize: bytes
            )
            try downloadsRepository.save(record: record)
            isDownloaded = true
        } catch {
            downloadErrorMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    deinit {
        player.pause()
        kvoTokens.forEach { $0.invalidate() }
        notifObservers.forEach { NotificationCenter.default.removeObserver($0) }
        cancellables.removeAll()
    }
}
