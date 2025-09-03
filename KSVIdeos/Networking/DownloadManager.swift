//
//  DownloadManager.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Foundation
import Combine

enum DownloadEvent {
    case progress(id: String, fraction: Double)
    case finished(id: String, fileURL: URL, bytes: Int64)
    case failed(id: String, error: Error)
}

protocol DownloadManagerProtocol: AnyObject {
    func startDownload(id: String, from url: URL) throws
    func cancelDownload(id: String)
    func isDownloading(id: String) -> Bool
    var events: AnyPublisher<DownloadEvent, Never> { get }
}
