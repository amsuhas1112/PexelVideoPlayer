import Foundation

// MARK: - Response

struct PexelsResponse: Codable {
    let page: Int
    let perPage: Int
    let videos: [PexelsVideo]
    let totalResults: Int
    let nextPage: String?
}

// MARK: - Video

struct PexelsVideo: Codable, Identifiable, Equatable {
    let id: Int
    let width: Int
    let height: Int
    let duration: Int
    let url: String
    let image: String
    let user: PexelsUser
    let videoFiles: [PexelsVideoFile]

    static func == (lhs: PexelsVideo, rhs: PexelsVideo) -> Bool { lhs.id == rhs.id }

    var formattedDuration: String {
        let m = duration / 60
        let s = duration % 60
        return m > 0 ? "\(m):\(String(format: "%02d", s))" : "0:\(String(format: "%02d", s))"
    }

    var pixelAspectRatio: CGFloat {
        return CGFloat(width) / CGFloat(height)
//        guard height > 0 else { return 16 / 9 }
//        return max(min(CGFloat(width) / CGFloat(height), 2.5), 0.4)
    }

//    /// Best HD/SD URL, prefers HD ~720p to balance quality vs bandwidth.
//    var bestVideoURL: URL? {
//        let mp4 = videoFiles.filter { $0.fileType == "video/mp4" }
//        // Pick highest quality HD ≤ 1080p wide, fall back to any
//        let preferred = mp4.filter { $0.quality == "hd" }.max(by: { $0.width < $1.width })
//            ?? mp4.filter { $0.quality == "sd" }.max(by: { $0.width < $1.width })
//            ?? mp4.first
//        guard let link = preferred?.link else { return nil }
//        return URL(string: link)
//    }
}

// MARK: - User

struct PexelsUser: Codable {
    let id: Int
    let name: String
    let url: String
}

// MARK: - VideoFile

struct PexelsVideoFile: Codable {
    let id: Int
    let quality: String
    let fileType: String
    let width: Int
    let height: Int
    let fps: Double?
    let link: String
    let size: Int?
}

