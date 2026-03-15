//
//  VideoPlayerController.swift
//  follow-realm
//
//  Created by Suhas A M on 15/03/26.
//

import AVFoundation


// MARK: - Controller

@Observable
@MainActor
final class VideoPlayerController {
    private(set) var player: AVPlayer?
    private(set) var currentVideo: PexelsVideo?
    private(set) var isReady = false
    private(set) var isMuted = false
    private(set) var selectedQuality: VideoQuality = .hd
    private(set) var currentAspectRatio: CGFloat = 16 / 9

    private var statusObservation: NSKeyValueObservation?
    private var endObserver: Any?

    func availableQualities(for video: PexelsVideo) -> [VideoQuality] {
        let present = Set(video.videoFiles.map { $0.quality.lowercased() })
        return VideoQuality.allCases.filter { present.contains($0.rawValue) }
    }

    func load(video: PexelsVideo, quality: VideoQuality) {
        selectedQuality = quality
        let resolved = resolvedQuality(quality, for: video)
        guard let url = url(for: video, quality: resolved) else {
            NSLog("[VideoPlayerController] No URL for video %d quality %@", video.id, quality.rawValue)
            return
        }
        currentVideo = video
        currentAspectRatio = video.pixelAspectRatio
        isReady = false

        let item = AVPlayerItem(url: url)
        observeStatus(of: item)
        observeEnd(of: item)

        if let existing = player {
            existing.replaceCurrentItem(with: item)
        } else {
            let p = AVPlayer(playerItem: item)
            p.volume = 1.0
            p.isMuted = isMuted
            player = p
        }
        player?.isMuted = isMuted
        player?.play()
    }

    func switchQuality(to quality: VideoQuality, for video: PexelsVideo) {
        guard let player else { return }
        let currentTime = player.currentTime()
        selectedQuality = quality
        let resolved = resolvedQuality(quality, for: video)
        guard let url = url(for: video, quality: resolved) else { return }
        isReady = false
        let item = AVPlayerItem(url: url)
        observeStatus(of: item, seekTo: currentTime)
        observeEnd(of: item)
        player.replaceCurrentItem(with: item)
        player.isMuted = isMuted
    }

    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
        player?.volume = isMuted ? 0 : 1
    }

    func cleanup() {
        statusObservation?.invalidate()
        statusObservation = nil
        if let obs = endObserver {
            NotificationCenter.default.removeObserver(obs)
            endObserver = nil
        }
        player?.pause()
        player = nil
        isReady = false
    }

    // MARK: - Private

    private func resolvedQuality(_ quality: VideoQuality, for video: PexelsVideo) -> VideoQuality {
        let available = availableQualities(for: video)
        if available.contains(quality) { return quality }
        return available.sorted(by: { $0.priority < $1.priority }).first ?? .sd
    }

    private func url(for video: PexelsVideo, quality: VideoQuality) -> URL? {
        let files = video.videoFiles.filter {
            $0.fileType == "video/mp4" && $0.quality.lowercased() == quality.rawValue
        }
        let best = files.max(by: { $0.width < $1.width }) ?? video.videoFiles.first
        guard let link = best?.link else { return nil }
        return URL(string: link)
    }

    private func observeStatus(of item: AVPlayerItem, seekTo time: CMTime? = nil) {
        statusObservation?.invalidate()
        statusObservation = item.observe(\.status, options: [.new, .initial]) { [weak self] obs, _ in
            guard obs.status == .readyToPlay else { return }
            Task { @MainActor [weak self] in
                if let time, time.isValid, time.seconds > 0 {
                    await self?.player?.seek(to: time)
                }
                self?.player?.play()
                self?.isReady = true
            }
        }
    }

    private func observeEnd(of item: AVPlayerItem) {
        if let obs = endObserver { NotificationCenter.default.removeObserver(obs) }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.signalFinished() }
        }
    }

    private func signalFinished() {
        NotificationCenter.default.post(name: .videoPlayerDidFinish, object: currentVideo)
    }
}

extension Notification.Name {
    static let videoPlayerDidFinish = Notification.Name("videoPlayerDidFinish")
}
