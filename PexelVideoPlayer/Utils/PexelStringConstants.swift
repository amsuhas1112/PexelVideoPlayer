
struct PexelStringConstants {
    // MARK: - Home
    static let exploreTitle = "Explore"
    static let searchPrompt = "Filter by creator…"
    static let loadVideos = "Load Videos"
    static let nextUp = "Next Up"

    // MARK: - Empty state
    static let noVideosTitle = "No Videos Yet"
    static let noVideosMessage = "Discover trending videos from talented creators around the world."

    // MARK: - Error state
    static let errorTitle = "Something Went Wrong"
    static let tryAgain = "Try Again"

    // MARK: - Error descriptions
    static let errorInvalidURL = "Invalid request URL."
    static let errorRateLimited = "API rate limit reached. Please try again later."
    static let errorDecoding = "Failed to process server response."
    static func errorServer(_ code: Int) -> String { "Server error (code: \(code))." }
    static func errorNetwork(_ msg: String) -> String { "Network error: \(msg)" }

    // MARK: - Player
    static let mute = "Mute"
    static let unmute = "Unmute"

    // MARK: - Load more errors
    static let loadMoreErrorTitle = "Couldn't load more videos"
    static let retryLoadMore = "Retry"

    // MARK: - Accessibility
    static let retryIcon = "arrow.clockwise"
    static let errorIcon = "wifi.exclamationmark"
    static let emptyIcon = "film.stack"
}
