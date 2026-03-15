import SwiftUI
import UIKit

/// AsyncImage replacement backed by NSCache.
/// Uses a fixed frame to prevent layout shifts when images load/evict.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?
    @State private var loadedURL: URL?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .onAppear { startLoadIfNeeded() }
        .onChange(of: url) { _, _ in
            uiImage = nil
            loadedURL = nil
            loadTask?.cancel()
            loadTask = nil
            startLoadIfNeeded()
        }
        .onDisappear {
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                loadTask?.cancel()
                loadTask = nil
            }
        }
    }

    // MARK: - Load

    private func startLoadIfNeeded() {
        guard let url, url != loadedURL else { return }
        // Already loading this URL
        if let task = loadTask, !task.isCancelled { return }
        // Serve from cache synchronously
        if let cached = ImageCache.shared.image(for: url) {
            uiImage = cached
            loadedURL = url
            return
        }
        let target = url
        loadTask = Task.detached(priority: .utility) {
            guard let (data, _) = try? await URLSession.shared.data(from: target),
                  !Task.isCancelled,
                  let img = UIImage(data: data) else { return }
            ImageCache.shared.store(img, for: target)
            await MainActor.run {
                guard !Task.isCancelled else { return }
                uiImage = img
                loadedURL = target
            }
        }
    }
}
