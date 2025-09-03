# KSVideos – README

> A small Swift/SwiftUI video app that showcases **Clean Architecture + SOLID**, protocol-oriented testability, custom image caching, and a robust **download manager** built on `URLSession` + `Combine`.  
> No external packages. Plain Swift.

---

## Table of contents

- [Targets & Requirements](#targets--requirements)  
- [Architecture](#architecture)  
- [Key Design Decisions](#key-design-decisions)  
- [Video Playback & Buffering](#video-playback--buffering)  
- [Download Handling](#download-handling)  
- [Image Loading & Cache](#image-loading--cache)  
- [Dependency Injection](#dependency-injection)  
- [Testing](#testing)  
- [Build & Run](#build--run)  
- [Roadmap / Nice-to-haves](#roadmap--nice-to-haves)  

---

## Targets & Requirements

- **Xcode:** 16.3+ (that’s what I used; older/newer may also work)  
- **iOS:** 17+ (adjust the deployment target if needed)  
- **Languages/Frameworks:** Swift, SwiftUI, Combine, AVKit, Foundation  
- **3rd-party deps:** **None** (vanilla Swift project)

---

## Architecture

**Clean Architecture** with **SOLID** principles:

- **Domain** (business rules): entity models and repository protocols.
- **Data** (implementations): API/persistence & repository impls conforming to domain protocols.
- **Presentation** (SwiftUI): views + observable view models, minimal business logic.
- **Adapters**: thin wrappers to present UIKit views in SwiftUI when beneficial (e.g. `AVPlayerViewController`).

**Why this split?**
- Replaceable boundaries (e.g. swap the API or persistence).
- Protocols enable test doubles and high testability.
- Clear dependency direction: UI → Domain abstractions → Data implementations.

---

## Key Design Decisions

1. **AVPlayer UI via `UIViewControllerRepresentable`**  
   I intentionally present **`AVPlayerViewController`** (wrapped in `AVPlayerViewControllerContainer`) instead of `SwiftUI.VideoPlayer`.  
   *Why:* richer built-in controls, better AirPlay/route handling, and parity with UIKit behaviors. Also AVPlayerViewController is well known.

2. **Protocol-oriented design for testability**  
   `DownloadsRepository`, `VideosRepository`, `HttpClientProtocol`, and `DownloadManagerProtocol` make the app easy to mock in unit tests.

3. **Simple DI Container**  
   `DependencyManager` wires the graph at app start. It produces protocol types (not concretes) to keep the call sites clean.

4. **No third-party packages**  
   Everything (image cache, download manager, player container) is implemented with system frameworks to keep the project light and portable.

---

## Video Playback & Buffering

**Goal:** reflect player state (playing/buffering/error) in the UI with minimal coupling.

- `VideoDetailViewModel` owns an `AVPlayer` and exposes:
  - `@Published var showPlayer: Bool`
  - `@Published private(set) var isPlaying: Bool`
  - `@Published private(set) var isBuffering: Bool`
  - `@Published private(set) var errorMessage: String?`

**How buffering is detected (high level):**

- Observe `AVPlayer.timeControlStatus` and/or `AVPlayerItem.isPlaybackLikelyToKeepUp`.
- Treat `.waitingToPlayAtSpecifiedRate` or `!isPlaybackLikelyToKeepUp` as **buffering**.
- Treat `.playing` with `isPlaybackLikelyToKeepUp == true` as **not buffering**.
- Map KVO changes to Combine publishers to update the `@Published` properties on the main actor.

This yields responsive UI state (spinner while buffering, play/pause indicators, etc.) without leaking AVKit specifics outside the view model.

---

## Download Handling

**Public Protocol**

```swift
enum DownloadEvent {
    case progress(id: String, fraction: Double)
    case finished(id: String, fileURL: URL, bytes: Int64)
    case failed(id: String, error: Error)
}

protocol DownloadManagerProtocol: AnyObject {
    func startDownload(id: String, from url: URL) throws
    func cancelDownload(id: String)
    func isDownloading(id: String) -> Bool
    var events: AnyPublisher<DownloadEvent, Never> { get }
}
```

**Concrete Implementation: `URLSessionDownloadManager`**

- Built on **`URLSessionDownloadTask`** + **`URLSessionDownloadDelegate`**.
- Emits **typed events** over **Combine** (`PassthroughSubject`) so view models/UI can react in real time.
- Keeps **internal maps** to correlate tasks with logical IDs:
  - `tasksById: [String: URLSessionDownloadTask]`
  - `idByTask: [Int: String]` (taskIdentifier → id)
  - `sourceURLById: [String: URL]` (for extension resolution)
- **Destination folder**: Documents/`Downloads` (created if missing).
- **File naming/extension**: tries (1) source URL ext, (2) `suggestedFilename`, defaulting to `mp4`.
- **Atomic move**: temp file is **moved** to final destination inside `didFinishDownloadingTo` *before* signaling completion.
- **iCloud backup**: destination gets `isExcludedFromBackup = true`.
- **Resilience**: duplicate `startDownload(id:)` are ignored; `cancel` cleans maps; failures emit `.failed`.
- **Progress**: `didWriteData` computes `fraction = totalBytesWritten / totalBytesExpectedToWrite` (guards against `-1`).

**Why a custom manager?**

- Fine-grained control of lifecycle, progress, file placement, and eventing without adding dependencies.
- Explicit, testable contract via `DownloadManagerProtocol`.

---

## Image Loading & Cache

- `ImageLoader` provides async image fetches with an in-memory **`ImageCache`**.
- `CachedAsyncImage` is a lightweight SwiftUI view that:
  - checks cache → loads via loader → caches on success.
  - avoids duplicate in-flight requests per URL.
- Simple, dependency-free alternative to 3rd-party image libraries.

---

## Dependency Injection

- `DependencyManager` is a minimal, explicit DI **container**:
  - Builds singletons (e.g., repositories, HTTP client, download manager).
  - Exposes **protocol types** to call sites:
    - `VideosRepositoryProtocol`
    - `DownloadsRepositoryProtocol`
    - `HttpClientProtocol`
    - `DownloadManagerProtocol`
- Views/ViewModels receive dependencies through initializers (preferred) or via environment injection when necessary.

---

## Testing

- **Protocols** make mocking straightforward (e.g., `HttpClientProtocol`, `DownloadManagerProtocol`).
- Example tests live under `KSVideosTests/`.
- You can create **test doubles** (e.g., a `MockDownloadManager`) that push `DownloadEvent` sequences to assert UI state transitions and persistence.

**Run tests**

- In Xcode: `Product → Test` or `⌘U`.
- From CLI: `xcodebuild -scheme KSVideos -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test`

---

## Build & Run

1. **Clone** the repo and open `KSVideos.xcodeproj` in **Xcode 16.3+**.
2. Select the **KSVideos** scheme and a simulator (e.g., iPhone 15 Pro).
3. **Run** (`⌘R`).

> The project is self-contained: no CocoaPods/SPM/Carthage setup, no extra scripts. If you run on a real device, ensure your team signing is selected in the target settings.

---

## Roadmap / Nice-to-haves

- Background download support with `URLSessionConfiguration.background` + reattachment.
- Persisted download states / resume support across launches.
- Disk cache for images with LRU eviction.
- Offline playback integration with `AVAssetDownloadURLSession` for HLS, if the catalog uses HLS streams.

---

## Credits

Created by **Guillermo Herrera**.  
Architecture, download manager, image loader, and UIKit bridge are all hand-rolled to keep the project lightweight and educational.
