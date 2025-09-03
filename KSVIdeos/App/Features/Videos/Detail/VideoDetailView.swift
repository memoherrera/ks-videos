//
//  VideoDetailView.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import SwiftUI
import AVKit

struct VideoDetailView: View {
    @Environment(\.navNamespace) private var navNS
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    @StateObject var viewModel: VideoDetailViewModel

    init(viewModel: VideoDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    private var isWide: Bool {
        (hSize == .compact && vSize == .compact) || hSize == .regular
    }

    var body: some View {
        Group {
            if isWide {
                ScrollView {
                    HStack(alignment: .top, spacing: 24) {
                        videoArea
                            .frame(maxWidth: .infinity)
                        detailsArea
                            .frame(width: 360)
                    }
                    .padding(16)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        videoArea
                        detailsArea
                    }
                    .padding(16)
                }
            }
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var videoArea: some View {
        ZStack {
            poster
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .opacity(viewModel.showPlayer ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: viewModel.showPlayer)
                .modifier(ZoomDestinationIfAvailable(
                    id: "video-thumb-\(viewModel.item.id)",
                    namespace: navNS
                ))

            if viewModel.showPlayer {
                AVPlayerViewControllerContainer(player: viewModel.player)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .transition(.opacity)
            }

            if !viewModel.showPlayer {
                Button(action: { viewModel.startPlayback() }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(24)
                        .background(.black.opacity(0.65))
                        .clipShape(Circle())
                        .shadow(radius: 8, y: 4)
                }
            }

            if viewModel.isBuffering {
                Color.black.opacity(0.25)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                    .padding()
                    .background(.ultraThinMaterial, in: Capsule())
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
    }

    private var poster: some View {
        CachedAsyncImage(url: viewModel.item.thumbnailURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Rectangle().fill(.secondary.opacity(0.15))
        }
        .clipped()
    }

    private var detailsArea: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.item.title)
                .font(.title2.bold())

            HStack(spacing: 8) {
                Text(viewModel.item.author)
                Text("•")
                Text("\(viewModel.item.viewsText) views")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Text(viewModel.item.descriptionText)
                .font(.body)

            downloadSection
        }
        .accessibilityElement(children: .contain)
    }

    private var downloadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                viewModel.startDownload()
            } label: {
                Label {
                    Text(viewModel.isDownloaded ? "Downloaded"
                         : viewModel.isDownloading ? "Downloading…" : "Download")
                } icon: {
                    Image(systemName: viewModel.isDownloaded
                          ? "checkmark.circle.fill"
                          : "arrow.down.circle")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isDownloaded || viewModel.isDownloading)

            if viewModel.isDownloading {
                ProgressView(value: viewModel.downloadProgress)
                    .frame(maxWidth: .infinity)
                    .animation(.linear, value: viewModel.downloadProgress)
            }

            if let err = viewModel.downloadErrorMessage {
                Text(err).font(.footnote).foregroundStyle(.red)
            }
        }
        .padding(.top, 8)
    }
}


