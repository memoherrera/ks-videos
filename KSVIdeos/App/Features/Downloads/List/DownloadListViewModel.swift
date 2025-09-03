//
//  DownloadListViewModel.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Foundation
import Combine

final class DownloadListViewModel: ObservableObject {
    
    struct PlayerSheetItem: Identifiable, Equatable {
        let id = UUID()
        let url: URL
    }

    @Published private(set) var rows: [DownloadedVideoUI] = []
    @Published var errorMessage: String?
    @Published var playerSheetItem: PlayerSheetItem?
    
    private let repo: DownloadsRepository
    private var bag = Set<AnyCancellable>()

    init(repo: DownloadsRepository) {
        self.repo = repo
    }

    func load() {
        do {
            let items = try repo.fetchAll()
            rows = items
        } catch {
            errorMessage = "Failed to load downloads: \(error.localizedDescription)"
        }
    }
    
    func play(id: String) {
        guard let row = rows.first(where: { $0.id == id }) else { return }
        playerSheetItem = PlayerSheetItem(url: row.fileURL)
    }

    func delete(id: String) {
        
        do {
            try repo.delete(videoId: id)
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
        // If the deleted item is currently shown, close the sheet
        if playerSheetItem?.url == rows.first(where: { $0.id == id })?.fileURL {
           playerSheetItem = nil
        }
        load()
    }
    
    func delete(at offsets: IndexSet) {
        for i in offsets {
          let id = rows[i].id
          do {
              try repo.delete(videoId: id)
              if playerSheetItem?.url == rows.first(where: { $0.id == id })?.fileURL {
                  playerSheetItem = nil
              }
          } catch {
              errorMessage = "Delete failed: \(error.localizedDescription)"
          }
        }
        load()
    }
}
