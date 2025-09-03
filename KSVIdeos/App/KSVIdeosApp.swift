//
//  KSVIdeosApp.swift
//  KSVIdeos
//
//  Created by Guillermo Herrera
//

import SwiftUI
import SwiftData

@main
struct KSVIdeosApp: App {

    var sharedModelContainer: ModelContainer = {
            let schema = Schema([ DownloadRecord.self ])

            let base = try! FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true
            )
            let folder = base.appendingPathComponent("KSVideos", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

            let storeURL = folder.appendingPathComponent("Downloads.store")

            let config = ModelConfiguration(
                schema: schema,
                url: storeURL
            )

            do {
                let container = try ModelContainer(for: schema, configurations: [config])
                #if DEBUG
                print("SwiftData store:", storeURL.path)
                print("Bundle ID:", Bundle.main.bundleIdentifier ?? "—")
                #endif

                return container
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.modelContainer(sharedModelContainer)
    }
}
