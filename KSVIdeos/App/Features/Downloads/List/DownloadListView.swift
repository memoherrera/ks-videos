//
//  DownloadListView.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//


import SwiftUI
import AVKit

struct DownloadListView: View {
    @StateObject var viewModel: DownloadListViewModel
    @Environment(\.horizontalSizeClass) private var hSize

    init(viewModel: DownloadListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            if viewModel.rows.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36, weight: .regular))
                            .foregroundStyle(.secondary)
                        Text("No downloads yet")
                            .font(.headline)
                        Text("Downloaded videos will appear here for offline playback.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            } else {
                ForEach(viewModel.rows) { row in
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title).font(.headline).lineLimit(2)
                            HStack(spacing: 8) {
                                Text(row.fileSizeString)
                                Text("•")
                                Text(row.dateString)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()

                        Menu {
                            Button {
                                viewModel.play(id: row.id)
                            } label: {
                                Label("Play", systemImage: "play.fill")
                            }
                            Button(role: .destructive) {
                                viewModel.delete(id: row.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.play(id: row.id) }
                }
                .onDelete(perform: viewModel.delete(at:))
            }
        }
        .frame(maxWidth: (hSize == .regular) ? 700 : nil, alignment: .center)
        .listStyle(.insetGrouped)
        .navigationTitle("Downloads")
        .toolbar { EditButton() }
        .onAppear { viewModel.load() }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK") { viewModel.errorMessage = nil }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .sheet(item: $viewModel.playerSheetItem) { item in
            LocalPlayerSheet(url: item.url)
                .ignoresSafeArea()
        }
    }
}

// Helper to present AVPlayer
private struct LocalPlayerSheet: View, Identifiable {
    let id = UUID()
    let url: URL
    @State private var player: AVPlayer = .init()

    var body: some View {
        ZStack {
            AVPlayerViewControllerContainer(player: player)
        }
        .onAppear {
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
            player.play()
        }
        .onDisappear { player.pause() }
    }
}
