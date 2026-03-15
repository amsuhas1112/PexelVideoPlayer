import SwiftUI

struct EmptyStateView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            iconSection
            textSection
            retryButton
            Spacer()
        }
        .padding(32)
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 100, height: 100)
            Image(systemName: PexelStringConstants.emptyIcon)
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)
        }
    }

    private var textSection: some View {
        VStack(spacing: 8) {
            Text(PexelStringConstants.noVideosTitle)
                .font(.title3)
                .fontWeight(.bold)
            Text(PexelStringConstants.noVideosMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var retryButton: some View {
        Button(action: onRetry) {
            Label(PexelStringConstants.loadVideos, systemImage: PexelStringConstants.retryIcon)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor, in: Capsule())
                .foregroundStyle(.white)
        }
    }
}

struct ErrorBannerView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            errorIcon
            errorText
            retryButton
            Spacer()
        }
        .padding(32)
    }

    private var errorIcon: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.1))
                .frame(width: 100, height: 100)
            Image(systemName: PexelStringConstants.errorIcon)
                .font(.system(size: 40))
                .foregroundStyle(.red)
        }
    }

    private var errorText: some View {
        VStack(spacing: 8) {
            Text(PexelStringConstants.errorTitle)
                .font(.title3)
                .fontWeight(.bold)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var retryButton: some View {
        Button(action: onRetry) {
            Label(PexelStringConstants.tryAgain, systemImage: PexelStringConstants.retryIcon)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.red, in: Capsule())
                .foregroundStyle(.white)
        }
    }
}
