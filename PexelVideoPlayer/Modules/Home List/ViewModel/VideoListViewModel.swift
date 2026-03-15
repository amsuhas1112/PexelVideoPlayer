import Foundation
import Observation

// MARK: - ViewModel

@Observable
@MainActor
final class VideoListViewModel {
    private(set) var allVideos: [PexelsVideo] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var errorMessage: String?
    /// Non-fatal error while paginating (load-more / next-up trigger).
    private(set) var loadMoreErrorMessage: String?
    private(set) var hasMorePages = true

    /// Filters already-loaded videos by name — no API call.
    var searchQuery: String = ""

    /// Simple search logic, can be improved with tokenized approach
    var videos: [PexelsVideo] {
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return allVideos }
        return allVideos.filter { $0.user.name.lowercased().contains(q) }
    }

    var showEmptyState: Bool { !isLoading && allVideos.isEmpty && errorMessage == nil }

    private var currentPage = 1
    private let perPage = 15
    /// Trigger a prefetch when this many items remain before the end.
    private let prefetchOffset = 5
    private let service: PexelsAPIServiceProtocol

    init(service: PexelsAPIServiceProtocol? = nil) {
        self.service = service ?? PexelsAPIService.shared
    }

    // MARK: - Public

    func loadInitialVideos() async {
        guard allVideos.isEmpty else { return }
        await fetch(reset: false)
    }

    /// Pull-to-refresh: clears everything and reloads page 1.
    func refresh() async {
        await fetch(reset: true)
    }

    /// Called from both the grid and the player's "Next Up" list.
    /// Triggers a load when `triggerID` is within `prefetchOffset` of the end.
    func loadMoreIfNeeded(triggerID: Int) async {
        guard let idx = allVideos.firstIndex(where: { $0.id == triggerID }) else { return }
        let threshold = allVideos.count - prefetchOffset
        guard idx >= threshold else { return }
        await loadMoreVideos()
    }

    func retry() async {
        allVideos = []
        errorMessage = nil
        loadMoreErrorMessage = nil
        await fetch(reset: false)
    }

    func retryLoadMore() async {
        loadMoreErrorMessage = nil
        await loadMoreVideos()
    }

    // MARK: - Private

    private func fetch(reset: Bool) async {
        if reset {
            allVideos = []
            currentPage = 1
            hasMorePages = true
            errorMessage = nil
            loadMoreErrorMessage = nil
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await service.fetchPopularVideos(page: currentPage, perPage: perPage)
            allVideos = response.videos
            hasMorePages = response.nextPage != nil
        } catch {
            errorMessage = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func loadMoreVideos() async {
        guard !isLoadingMore, hasMorePages, !isLoading else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let response = try await service.fetchPopularVideos(page: nextPage, perPage: perPage)
            let existingIDs = Set(allVideos.map(\.id))
            let unique = response.videos.filter { !existingIDs.contains($0.id) }
            allVideos.append(contentsOf: unique)
            currentPage = nextPage
            hasMorePages = response.nextPage != nil
            loadMoreErrorMessage = nil
        } catch {
            let msg = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
            loadMoreErrorMessage = msg
            NSLog("[VideoListViewModel] Load more error: %@", msg)
        }
    }
}
