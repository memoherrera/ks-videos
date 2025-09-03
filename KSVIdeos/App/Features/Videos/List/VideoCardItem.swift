//
//  VideoRow.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import SwiftUI

struct VideoCardItem: View {
    @Environment(\.navNamespace) private var navNS
    @Environment(\.horizontalSizeClass) private var hSize
    let item: VideoItemUI
    
    private var textVSpacing: CGFloat { hSize == .regular ? 8 : 6 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                CachedAsyncImage(url: item.thumbnailURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().opacity(0.08)
                }
                .aspectRatio(16.0/9.0, contentMode: .fit)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .modifier(ZoomDestinationIfAvailable(
                    id: "video-thumb-\(item.id)",
                    namespace: navNS
                ))

                if item.isLive {
                    HStack {
                        Text("LIVE")
                            .font(.caption).bold().foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(.black.opacity(0.85))
                            .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(12)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(item.durationText)
                            .font(.caption2).bold().foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.black.opacity(0.75))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: textVSpacing) {
                Text(item.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(item.title.uppercased())
                    .font(.headline).bold()
                    .lineLimit(3)

                HStack(spacing: 6) {
                    Text(item.uploadDateText)
                    Text("•")
                    Text("\(item.viewsText) views")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.black.opacity(0.05))
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.author), \(item.uploadDateText), \(item.viewsText) views")
    }
}
