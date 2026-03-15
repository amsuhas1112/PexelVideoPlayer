import SwiftUI
import AVKit

// MARK: - Root View

struct VideoPlayerView: View {
    let initialVideo: PexelsVideo
    /// Shared view-model so the player can trigger pagination.
    let viewModel: VideoListViewModel

    @State private var ctrl = VideoPlayerController()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                playerSection
                controlsBar
                infoSection
                nextUpSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .task { ctrl.load(video: initialVideo, quality: .hd) }
        .onDisappear { ctrl.cleanup() }
        .onReceive(NotificationCenter.default.publisher(for: .videoPlayerDidFinish)) { note in
            guard let finished = note.object as? PexelsVideo,
                  finished == ctrl.currentVideo else { return }
            withAnimation { autoplayNext(after: finished) }
        }
    }

    private var allVideos: [PexelsVideo] { viewModel.videos }

    private func autoplayNext(after video: PexelsVideo) {
        guard let idx = allVideos.firstIndex(of: video), idx + 1 < allVideos.count else { return }
        ctrl.load(video: allVideos[idx + 1], quality: ctrl.selectedQuality)
    }
}

// MARK: - Player Section

private extension VideoPlayerView {
    var playerSection: some View {
        ZStack {
            Color.black
            if let player = ctrl.player {
                VideoPlayer(player: player)
                    .opacity(ctrl.isReady ? 1 : 0)
                    .animation(.easeIn(duration: 0.25), value: ctrl.isReady)
            }
            if !ctrl.isReady {
                ProgressView().tint(.white).scaleEffect(1.3)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(ctrl.currentAspectRatio, contentMode: .fit)
    }

    var controlsBar: some View {
        HStack(spacing: 16) {
            Button { ctrl.toggleMute() } label: {
                Image(systemName: ctrl.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ctrl.isMuted ? .red : .primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.tertiarySystemGroupedBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(ctrl.isMuted ? PexelStringConstants.unmute : PexelStringConstants.mute)

            Spacer()

            let video = ctrl.currentVideo ?? initialVideo
            let options = ctrl.availableQualities(for: video)
            if !options.isEmpty {
                Menu {
                    ForEach(options, id: \.self) { q in
                        Button {
                            ctrl.switchQuality(to: q, for: video)
                        } label: {
                            HStack {
                                Text(q.label)
                                if q == ctrl.selectedQuality { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .semibold))
                        Text(ctrl.selectedQuality.label)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    var infoSection: some View {
        let video = ctrl.currentVideo ?? initialVideo
        return HStack {
            Label(video.user.name, systemImage: "person.fill")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Label(video.formattedDuration, systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }
}

// MARK: - Next Up Section

private extension VideoPlayerView {
    var nextUpSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(PexelStringConstants.nextUp)
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 14)

            LazyVStack(spacing: 0) {
                ForEach(upcomingVideos.prefix(20)) { vid in
                    NextUpRow(video: vid, isActive: vid == ctrl.currentVideo) {
                        ctrl.load(video: vid, quality: ctrl.selectedQuality)
                    }
                    .task { await viewModel.loadMoreIfNeeded(triggerID: vid.id) }

                    Divider().padding(.leading, 104)
                }

                // Pagination footer — spinner or error+retry
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
        }
    }

    var upcomingVideos: [PexelsVideo] {
        guard let current = ctrl.currentVideo,
              let idx = allVideos.firstIndex(of: current),
              idx + 1 < allVideos.count else { return allVideos }
        return Array(allVideos[(idx + 1)...])
    }
}

// MARK: - Next Up Row

private struct NextUpRow: View {
    let video: PexelsVideo
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                thumbnailView
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.user.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(video.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(isActive
                ? Color.accentColor.opacity(0.07)
                : Color(.secondarySystemGroupedBackground))
        }
        .buttonStyle(.plain)
    }

    private var thumbnailView: some View {
        CachedAsyncImage(url: URL(string: video.image)) { img in
            img.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Color(.systemGray5)
        }
        .frame(width: 80, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Quality Option

enum VideoQuality: String, CaseIterable, Hashable {
    case uhd, hd, sd

    var label: String {
        switch self {
        case .uhd: return "4K"
        case .hd:  return "HD"
        case .sd:  return "SD"
        }
    }

    var priority: Int {
        switch self {
        case .hd:  return 0
        case .uhd: return 1
        case .sd:  return 2
        }
    }
}
