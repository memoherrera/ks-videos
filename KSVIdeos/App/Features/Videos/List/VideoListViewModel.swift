//
//  VideoListViewModel.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//
import Foundation

public final class VideoListViewModel: ObservableObject {
    @Published private(set) var items: [VideoItemUI] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository: VideosRepository
    private let presenter: VideoPresenter

    public init(repository: VideosRepository, presenter: VideoPresenter = .init()) {
        self.repository = repository
        self.presenter = presenter
    }
    
    @MainActor
    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let videos = try await repository.getVideos()
            self.items = videos.map(presenter.present)
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Something went wrong. Please try again."
        }
    }
}
