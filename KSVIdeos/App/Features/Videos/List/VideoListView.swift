//
//  VideoListView.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//
import SwiftUI

struct VideoListView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject private var viewModel: VideoListViewModel
    
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    
    private var columns: [GridItem] {
        // iPad / large screens: 3–4 columns
        if hSize == .regular {
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
        }
        // iPhone landscape: 2 columns
        if hSize == .compact && vSize == .compact {
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        }
        // iPhone portrait: 1 column
        return [GridItem(.flexible(), spacing: 12)]
    }

    private var horizontalPadding: CGFloat {
        hSize == .regular ? 24 : 16
    }


    init(viewModel: VideoListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                VStack { ProgressView("Loading videos…") }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.errorMessage, viewModel.items.isEmpty {
                VStack(spacing: 12) {
                    Text(message).multilineTextAlignment(.center).foregroundColor(.secondary)
                    Button("Retry") { Task { await viewModel.load() } }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.items) { item in
                            Button {
                                coordinator.push(.videoDetail(item))
                            } label: {
                                VideoCardItem(item: item)
                            }
                            .buttonStyle(.plain) // keep card look
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 16)
                }
                .refreshable { await viewModel.load() }
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
        .navigationTitle("Videos")
        .task { await viewModel.load() }
    }
}

