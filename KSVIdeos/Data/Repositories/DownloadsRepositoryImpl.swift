//
//  DownloadsRepository.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import SwiftData
import Foundation

struct DownloadsRepositoryImpl: DownloadsRepository {
    func isDownloadedLocally(videoId: String) throws -> Bool {
        guard let rec = try fetchRecord(videoId: videoId) else { return false }
                return resolveExistingURL(for: rec) != nil
    }
    
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func exists(videoId: String) throws -> Bool {
        let descriptor = FetchDescriptor<DownloadRecord>(
            predicate: #Predicate { $0.videoId == videoId }
        )
        return try !context.fetch(descriptor).isEmpty
    }

    func save(record: DownloadRecord) throws {
        context.insert(record)
        try context.save()
    }
    
    public func fetchAll() throws -> [DownloadedVideoUI] {
        let desc = FetchDescriptor<DownloadRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let records = try context.fetch(desc)
        return records.compactMap { rec in
            guard let url = resolveExistingURL(for: rec) else { return nil }
            return DownloadedVideoUI(
                id: rec.videoId,
                title: rec.title,
                fileURL: url,
                fileSize: rec.fileSize,
                createdAt: rec.createdAt
            )
        }
    }

    public func delete(videoId: String) throws {
        let d = FetchDescriptor<DownloadRecord>(
            predicate: #Predicate { $0.videoId == videoId }
        )
        let items = try context.fetch(d)
        for r in items {
            if let url = resolveExistingURL(for: r) { try? FileManager.default.removeItem(at: url) }
            context.delete(r)
        }
        try context.save()
    }
    
    // MARK: - Helpers

    private func fetchRecord(videoId: String) throws -> DownloadRecord? {
        let d = FetchDescriptor<DownloadRecord>(
            predicate: #Predicate { $0.videoId == videoId }
        )
        return try context.fetch(d).first
    }

    /// Tries the stored absolute path; if missing, tries Documents/Downloads and
    /// Application Support/Downloads with the same filename. Returns the first that exists.
    private func resolveExistingURL(for rec: DownloadRecord) -> URL? {
        let fm = FileManager.default

        let stored = URL(fileURLWithPath: rec.localPath)
        if fm.fileExists(atPath: stored.path) { return stored }

        let fileName = stored.lastPathComponent
        var candidates: [URL] = []

        if let docs = try? fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            candidates.append(docs.appendingPathComponent("Downloads", isDirectory: true)
                                   .appendingPathComponent(fileName))
        }
        if let support = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            candidates.append(support.appendingPathComponent("Downloads", isDirectory: true)
                                      .appendingPathComponent(fileName))
        }

        return candidates.first(where: { fm.fileExists(atPath: $0.path) })
    }
}
