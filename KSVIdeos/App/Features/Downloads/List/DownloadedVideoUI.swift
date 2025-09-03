//
//  DownloadItemUI.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Foundation

public struct DownloadedVideoUI: Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let fileURL: URL
    public let fileSize: Int64
    public let createdAt: Date

    public init(id: String, title: String, fileURL: URL, fileSize: Int64, createdAt: Date) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.fileSize = fileSize
        self.createdAt = createdAt
    }
    
    var fileSizeString: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: createdAt)
    }
}
