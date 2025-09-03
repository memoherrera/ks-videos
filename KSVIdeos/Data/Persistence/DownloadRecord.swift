//
//  DownloadRecord.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import SwiftData
import Foundation

@Model
final class DownloadRecord {
    @Attribute(.unique) var videoId: String
    var title: String
    var localPath: String
    var fileSize: Int64
    var createdAt: Date

    init(videoId: String, title: String, localPath: String, fileSize: Int64, createdAt: Date = .now) {
        self.videoId = videoId
        self.title = title
        self.localPath = localPath
        self.fileSize = fileSize
        self.createdAt = createdAt
    }
}
