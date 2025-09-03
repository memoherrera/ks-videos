//
//  DependencyManager.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Foundation
import SwiftData

final class DependencyManager {

    static let shared = DependencyManager()
    
    private init() {}

    // MARK: - Shared Dependencies (lazy singletons)
    private lazy var httpClient: HttpClient = {
        HttpClient(baseURL: URL(string: "https://gist.githubusercontent.com/poudyalanil/ca84582cbeb4fc123a13290a586da925/raw/14a27bd0bcd0cd323b35ad79cf3b493dddf6216b/")!)
    }()

    private lazy var videosAPI: VideosAPIProtocol = {
        VideosAPI(client: httpClient)
    }()

    private lazy var videosRepository: VideosRepository = {
        VideosRepositoryImpl(api: videosAPI)
    }()
    
    // MARK: - ViewModel factories
    func makeVideoListViewModel() -> VideoListViewModel {
        VideoListViewModel(repository: videosRepository)
    }
    
    func makeVideoDetailViewModel(item: VideoItemUI, context: ModelContext) -> VideoDetailViewModel {
        let repo = DownloadsRepositoryImpl(context: context)
        let manager = URLSessionDownloadManager()
        return VideoDetailViewModel(item: item, downloadManager: manager, downloadsRepository: repo)
    }
    
    func makeDownloadListViewModel(context: ModelContext) -> DownloadListViewModel  {
        let repo = DownloadsRepositoryImpl(context: context)
        let vm = DownloadListViewModel(repo: repo)
        return vm
    }
}
