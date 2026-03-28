import Foundation

/// Highlight videos and condensed game clips for a single MLB game.
///
/// Returned by ``SwiftBaseball/gameHighlights(gamePk:)``.
///
/// ```swift
/// let content = try await SwiftBaseball.gameHighlights(gamePk: 745612).fetch()
/// for clip in content.highlights {
///     print(clip.title ?? "", clip.duration ?? "")
/// }
/// ```
public struct GameHighlights: Codable, Sendable, Equatable {
    /// Key-play highlight clips shown in the game center (home runs, strikeouts, scoring plays, etc.).
    public let highlights: [Highlight]
    /// Condensed game and scoreboard clips.
    public let scoreboardHighlights: [Highlight]
}

/// A single highlight video clip.
public struct Highlight: Codable, Sendable, Equatable {
    /// Unique identifier for this highlight.
    public let id: String
    /// Publication date and time (UTC).
    public let date: Date?
    /// Short display title.
    public let title: String?
    /// Longer headline suitable for display above the clip.
    public let headline: String?
    /// Brief description of the play or event.
    public let blurb: String?
    /// Clip duration formatted as `"HH:mm:ss"` (e.g. `"00:01:30"`).
    public let duration: String?
    /// Available video streams, typically ordered from highest to lowest quality.
    public let playbacks: [VideoPlayback]
    /// Thumbnail image at various resolutions.
    public let image: HighlightImage?
}

/// A single video stream for a ``Highlight``.
public struct VideoPlayback: Codable, Sendable, Equatable {
    /// Stream format name (e.g. `"mp4Avc"`, `"FLASH_2500K_1280X720"`).
    public let name: String
    /// Direct URL to the video file.
    public let url: URL?
    /// Video width in pixels.
    public let width: Int?
    /// Video height in pixels.
    public let height: Int?
}

/// Thumbnail image for a ``Highlight``, containing multiple resolution crops.
public struct HighlightImage: Codable, Sendable, Equatable {
    /// Accessibility alt text for the image.
    public let altText: String?
    /// Available image crops at different resolutions.
    public let cuts: [ImageCut]
}

/// A single resolution crop of a ``HighlightImage``.
public struct ImageCut: Codable, Sendable, Equatable {
    /// Aspect ratio string (e.g. `"16:9"`).
    public let aspectRatio: String?
    /// Image width in pixels.
    public let width: Int
    /// Image height in pixels.
    public let height: Int
    /// Direct URL to the image file.
    public let src: URL?
}
