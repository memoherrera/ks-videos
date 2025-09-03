//
//  URLSessionDownloadManager.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Foundation
import Combine
import UniformTypeIdentifiers

final class URLSessionDownloadManager: NSObject, DownloadManagerProtocol {
    private let baseFolder: URL
    private let makeSession: (URLSessionDownloadManager) -> URLSession
    
    private lazy var session: URLSession = makeSession(self)

    private var tasksById: [String: URLSessionDownloadTask] = [:]
    private var idByTask: [Int: String] = [:]
    private var sourceURLById: [String: URL] = [:]
    private let subject = PassthroughSubject<DownloadEvent, Never>()
    var events: AnyPublisher<DownloadEvent, Never> { subject.eraseToAnyPublisher() }

    // MARK: - Init
    init(
        baseFolder: URL? = nil,
        makeSession: ((URLSessionDownloadManager) -> URLSession)? = nil
    ) {
        let fileManager = FileManager.default
        if let baseFolder {
            self.baseFolder = baseFolder
        } else {
            let docs = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            self.baseFolder = docs.appendingPathComponent("Downloads", isDirectory: true)
        }

        // Default session factory (same behavior you had)
        self.makeSession = makeSession ?? { owner in
            let cfg = URLSessionConfiguration.default
            cfg.allowsExpensiveNetworkAccess = true
            cfg.allowsConstrainedNetworkAccess = true
            return URLSession(configuration: cfg, delegate: owner, delegateQueue: nil)
        }

        super.init()
        try? fileManager.createDirectory(at: self.baseFolder, withIntermediateDirectories: true)
    }

    // MARK: - API
    func startDownload(id: String, from url: URL) throws {
        guard tasksById[id] == nil else { return } // prevent duplicate
        sourceURLById[id] = url
        let task = session.downloadTask(with: url)
        tasksById[id] = task
        idByTask[task.taskIdentifier] = id
        task.resume()
    }

    func cancelDownload(id: String) {
        guard let task = tasksById[id] else { return }
        task.cancel()
        cleanup(for: id, taskId: task.taskIdentifier)
    }

    func isDownloading(id: String) -> Bool { tasksById[id] != nil }

    private func cleanup(for id: String, taskId: Int) {
        tasksById[id] = nil
        idByTask[taskId] = nil
        sourceURLById[id] = nil
    }
}

extension URLSessionDownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let id = idByTask[downloadTask.taskIdentifier] else { return }
        let fm = FileManager.default

        // Decide filename/extension
        let srcURL = sourceURLById[id]
        let suggested = downloadTask.response?.suggestedFilename
        let extFromSrc = srcURL?.pathExtension
        let extFromSuggested = suggested.flatMap { URL(fileURLWithPath: $0).pathExtension }
        let ext = [extFromSrc, extFromSuggested, "mp4"].compactMap { $0 }.first!.isEmpty ? "mp4" :
                  ([extFromSrc, extFromSuggested].compactMap{$0}.first ?? "mp4")

        var dest = baseFolder.appendingPathComponent("\(id).\(ext)")
        do {
            // Ensure folder exists
            try fm.createDirectory(at: baseFolder, withIntermediateDirectories: true)

            // Remove any stale file for same id
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }

            // Move *before* returning from delegate
            try fm.moveItem(at: location, to: dest)

            // Optional: exclude from iCloud backup if stored in Documents
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? dest.setResourceValues(values)

            let bytes = downloadTask.countOfBytesReceived
            subject.send(.finished(id: id, fileURL: dest, bytes: bytes))
        } catch {
            subject.send(.failed(id: id, error: error))
        }
        cleanup(for: id, taskId: downloadTask.taskIdentifier)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let id = idByTask[task.taskIdentifier] else { return }
        if let error { subject.send(.failed(id: id, error: error)) }
        cleanup(for: id, taskId: task.taskIdentifier)
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let id = idByTask[downloadTask.taskIdentifier],
              totalBytesExpectedToWrite > 0 else { return }
        let fraction = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        subject.send(.progress(id: id, fraction: fraction))
    }
}

