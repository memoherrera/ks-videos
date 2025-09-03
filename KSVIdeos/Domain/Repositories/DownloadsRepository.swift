//
//  DownloadsRepositoryProtocol.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//
import SwiftData

protocol DownloadsRepository {
    func exists(videoId: String) throws -> Bool
    func isDownloadedLocally(videoId: String) throws -> Bool
    func save(record: DownloadRecord) throws
    func fetchAll() throws -> [DownloadedVideoUI]
    func delete(videoId: String) throws
}
