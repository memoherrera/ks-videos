//
//  ImageLoader.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import UIKit

@MainActor
final class ImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?

    private var task: Task<Void, Never>?
    private(set) var url: URL?

    static let sharedCache: ImageCache = TemporaryImageCache()

    func load(_ url: URL) {
        self.url = url

        if let cached = Self.sharedCache[url] {
            self.image = cached
            return
        }

        task?.cancel()
        task = Task { [url] in
            do {
                let req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
                let (data, _) = try await URLSession.shared.data(for: req)
                guard !Task.isCancelled, let img = UIImage(data: data) else { return }

                Self.sharedCache[url] = img
                // We're already on the MainActor (class is @MainActor)
                if self.url == url { self.image = img }
            } catch {
                // Optional: handle error/cancellation
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
