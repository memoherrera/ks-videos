//
//  ImageCache.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import UIKit

protocol ImageCache: AnyObject {
    subscript(_ url: URL) -> UIImage? { get set }
}

final class TemporaryImageCache: ImageCache {
    private let cache = NSCache<NSURL, UIImage>()
    subscript(_ url: URL) -> UIImage? {
        get { cache.object(forKey: url as NSURL) }
        set {
            if let img = newValue { cache.setObject(img, forKey: url as NSURL) }
            else { cache.removeObject(forKey: url as NSURL) }
        }
    }
}
