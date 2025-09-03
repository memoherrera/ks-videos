//
//  ContentView.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Namespace private var navNS
    @Environment(\.modelContext) private var modelContext
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var videoListViewModel = DependencyManager.shared.makeVideoListViewModel()

    var body: some View {
        TabView {
            NavigationStack(path: $coordinator.path) {
                VideoListView(viewModel: videoListViewModel)
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .videoDetail(let item):
                            let detailViewModel = DependencyManager.shared.makeVideoDetailViewModel(item: item, context: modelContext)
                            VideoDetailView(viewModel: detailViewModel)
                        }
                    }
            }
            .tabItem { Label("Videos", systemImage: "list.bullet") }
            .tag(1)
            DownloadsTab(modelContext: modelContext)
                .tabItem { Label("Downloads", systemImage: "arrow.down.circle") }
                .tag(2)
            
        }
        .environmentObject(coordinator)
        .environment(\.navNamespace, navNS)
    }
}

struct DownloadsTab: View {
    @StateObject private var viewModel: DownloadListViewModel

    init(modelContext: ModelContext) {
        _viewModel = StateObject(
            wrappedValue: DependencyManager.shared.makeDownloadListViewModel(context: modelContext)
        )
    }

    var body: some View {
        NavigationStack {
            DownloadListView(viewModel: viewModel)
                .navigationTitle("Downloads")
        }
    }
}

#Preview {
    ContentView()
}
