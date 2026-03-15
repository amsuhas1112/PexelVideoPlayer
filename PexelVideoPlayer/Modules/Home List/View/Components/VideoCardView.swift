import SwiftUI

struct VideoCardView: View {
    let video: PexelsVideo
    /// Column width passed from parent to compute fixed image height.
    var columnWidth: CGFloat = 120

    private var imageHeight: CGFloat {
        columnWidth / video.pixelAspectRatio
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            thumbnailStack
            nameLabel
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Thumbnail

    private var thumbnailStack: some View {
        ZStack(alignment: .bottomTrailing) {
            CachedAsyncImage(url: URL(string: video.image)) { img in
                img.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(.systemGray5).shimmer()
            }
            .frame(width: columnWidth, height: imageHeight)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            durationBadge
        }
    }

    // MARK: - Badge

    private var durationBadge: some View {
        Text(video.formattedDuration)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.black.opacity(0.65), in: Capsule())
            .padding(5)
    }

    // MARK: - Name

    private var nameLabel: some View {
        Text(video.user.name)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
    }
}
