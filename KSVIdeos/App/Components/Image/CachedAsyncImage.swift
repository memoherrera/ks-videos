//
//  CachedAsyncImage.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    @StateObject private var loader = ImageLoader()
    let url: URL
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    init(url: URL,
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack {
            if let ui = loader.image {
                content(Image(uiImage: ui).renderingMode(.original))
                    // critical: no inner fade animation to interfere with zoom
                    .transaction { $0.animation = nil }
            } else {
                placeholder()
            }
        }
        .onAppear { loader.load(url) }
        .onDisappear { loader.cancel() }
    }
}
