//
//  PexelVideoPlayerApp.swift
//  PexelVideoPlayer
//
//  Created by Suhas A M on 15/03/26.
//

import SwiftUI
import AVFoundation

@main
struct PexelVideoPlayerApp: App {
    init() {
        configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(nil)
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
            try session.setActive(true)
        } catch {
            NSLog("[FollowRealm] AVAudioSession setup failed: %@", error.localizedDescription)
        }
    }
}
