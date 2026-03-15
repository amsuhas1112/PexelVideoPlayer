import SwiftUI

struct HomeView: View {
    @State private var viewModel = VideoListViewModel()

    private let columns = 3
    private let spacing: CGFloat = 10

    var body: some View {
        NavigationStack {
            // GeometryReader is OUTSIDE NavigationStack scroll content
            // so it never re-fires during scrolling.
            GeometryReader { geo in
                let colWidth = (geo.size.width - spacing * CGFloat(columns + 1)) / CGFloat(columns)
                contentView(colWidth: colWidth)
                    .navigationTitle(PexelStringConstants.exploreTitle)
                    .background(Color(.systemGroupedBackground))
                    .searchable(text: $viewModel.searchQuery, prompt: PexelStringConstants.searchPrompt)
                    .task { await viewModel.loadInitialVideos() }
            }
        }
        .tint(Color.accentColor)
    }

    // MARK: - Content switcher

    @ViewBuilder
    private func contentView(colWidth: CGFloat) -> some View {
        if viewModel.isLoading {
            ScrollView { ShimmerGridView(colWidth: colWidth, columns: columns, spacing: spacing).padding(.top, 4) }
        } else if let error = viewModel.errorMessage {
            ErrorBannerView(message: error) {
                Task { await viewModel.retry() }
            }
        } else if viewModel.showEmptyState {
            EmptyStateView { Task { await viewModel.loadInitialVideos() } }
        } else if viewModel.videos.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchQuery)
        } else {
            masonryScrollView(colWidth: colWidth)
        }
    }

    // MARK: - Masonry scroll

    private func masonryScrollView(colWidth: CGFloat) -> some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                MasonryGrid(
                    items: viewModel.videos,
                    columns: columns,
                    spacing: spacing,
                    columnWidth: colWidth,
                    heightProvider: { cardHeight(for: $0, colWidth: colWidth) }
                ) { video in
                    NavigationLink(destination: VideoPlayerView(
                        initialVideo: video,
                        viewModel: viewModel
                    )) {
                        VideoCardView(video: video, columnWidth: colWidth)
                    }
                    .buttonStyle(.plain)
                    .onAppear { Task { await viewModel.loadMoreIfNeeded(triggerID: video.id) } }
                }

                paginationFooter
            }
        }
        .refreshable { await viewModel.refresh() }
    }

    // MARK: - Pagination footer

    @ViewBuilder
    private var paginationFooter: some View {
        if viewModel.isLoadingMore {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        } else if let loadMoreErr = viewModel.loadMoreErrorMessage {
            LoadMoreErrorView(message: loadMoreErr) {
                Task { await viewModel.retryLoadMore() }
            }
        }
    }

    // MARK: - Height helpers

    private func cardHeight(for video: PexelsVideo, colWidth: CGFloat) -> CGFloat {
        let imgH = colWidth / video.pixelAspectRatio
        return imgH + 22
    }
}

// MARK: - Load-more error footer

struct LoadMoreErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: PexelStringConstants.errorIcon)
                    .foregroundStyle(.red)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button(action: onRetry) {
                Label(PexelStringConstants.tryAgain, systemImage: PexelStringConstants.retryIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }
}
