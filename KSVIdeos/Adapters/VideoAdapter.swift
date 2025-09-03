//
//  VideoAdapter.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import Foundation

// MARK: - Mapping Errors

public enum VideoMappingError: Error, LocalizedError {
    case invalidThumbnailURL(String)
    case invalidVideoURL(String)
    case invalidDuration(String)
    case invalidDate(String)
    case invalidViews(String)

    public var errorDescription: String? {
        switch self {
        case .invalidThumbnailURL(let s): return "Invalid thumbnail URL: \(s)"
        case .invalidVideoURL(let s):     return "Invalid video URL: \(s)"
        case .invalidDuration(let s):     return "Invalid duration: \(s)"
        case .invalidDate(let s):         return "Invalid date: \(s)"
        case .invalidViews(let s):        return "Invalid views: \(s)"
        }
    }
}

// MARK: - Adapter (DTO -> Domain)
public struct VideoAdapter {
    public init() {}

    public func map(_ dto: VideoItemDTO) throws -> Video {
        let thumb = try parseURL(dto.thumbnailUrl, error: .invalidThumbnailURL(dto.thumbnailUrl))
        let video = try parseURL(dto.videoUrl,      error: .invalidVideoURL(dto.videoUrl))
        let seconds = try parseDuration(dto.duration)
        let date = try parseDate(dto.uploadTime)
        let views = try parseIntWithCommas(dto.views)
        let subs = parseSubscriberCount(dto.subscriber)

        return Video(
            id: dto.id,
            title: dto.title,
            thumbnailURL: thumb,
            durationSeconds: seconds,
            uploadDate: date,
            viewCount: views,
            author: dto.author,
            videoURL: video,
            description: dto.description,
            subscriberCount: subs,
            isLive: dto.isLive
        )
    }
}

// MARK: - Parsing helpers

private extension VideoAdapter {
    func parseURL(_ string: String, error: VideoMappingError) throws -> URL {
        guard let url = URL(string: string) else { throw error }
        return url
    }

    /// Supports "mm:ss" and "hh:mm:ss".
    func parseDuration(_ string: String) throws -> Int {
        let parts = string.split(separator: ":").map(String.init)
        guard (2...3).contains(parts.count),
              parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else {
            throw VideoMappingError.invalidDuration(string)
        }

        func toInt(_ s: String) -> Int { Int(s) ?? 0 }

        if parts.count == 2 {
            let m = toInt(parts[0]), s = toInt(parts[1])
            return m * 60 + s
        } else {
            let h = toInt(parts[0]), m = toInt(parts[1]), s = toInt(parts[2])
            return h * 3600 + m * 60 + s
        }
    }

    func parseDate(_ string: String) throws -> Date {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.dateFormat = "MMM d, yyyy"
        if let date = fmt.date(from: string) { return date }
        throw VideoMappingError.invalidDate(string)
    }

    /// Parses "24,969,123" -> 24969123
    func parseIntWithCommas(_ string: String) throws -> Int {
        let cleaned = string.replacingOccurrences(of: ",", with: "")
        guard let value = Int(cleaned) else { throw VideoMappingError.invalidViews(string) }
        return value
    }

    /// Parses "25254545 Subscribers" -> 25254545 (optional).
    func parseSubscriberCount(_ string: String) -> Int? {
        let digits = string.compactMap { $0.isNumber ? $0 : nil }
        return Int(String(digits))
    }
}

// MARK: - Convenience: bulk mapping

public extension Array where Element == VideoItemDTO {
    func toDomain(using mapper: VideoAdapter = .init()) -> Result<[Video], Error> {
        do { return .success(try self.map(mapper.map)) }
        catch { return .failure(error) }
    }
}

