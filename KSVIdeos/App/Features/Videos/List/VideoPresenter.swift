//
//  VideoItemUI.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//
import Foundation

public struct VideoItemUI: Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let thumbnailURL: URL
    public let playURL: URL
    public let descriptionText: String
    public let durationText: String
    public let uploadDateText: String
    public let viewsText: String
    public let author: String
    public let isLive: Bool
}

public struct VideoPresenter {
    private let dateFormatter: DateFormatter
    private let numberFormatter: NumberFormatter

    public init(locale: Locale = .current) {
        dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        numberFormatter = NumberFormatter()
        numberFormatter.locale = locale
        numberFormatter.numberStyle = .decimal
    }

    public func present(_ v: Video) -> VideoItemUI {
        VideoItemUI(
            id: v.id,
            title: v.title,
            thumbnailURL: v.thumbnailURL,
            playURL: v.videoURL,
            descriptionText: v.description,
            durationText: formatDuration(v.durationSeconds),
            uploadDateText: dateFormatter.string(from: v.uploadDate),
            viewsText: numberFormatter.string(from: NSNumber(value: v.viewCount)) ?? "\(v.viewCount)",
            author: v.author,
            isLive: v.isLive
        )
    }

    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s)
                     : String(format: "%d:%02d", m, s)
    }
}
