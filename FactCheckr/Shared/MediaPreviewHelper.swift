import UIKit
import LinkPresentation

struct MediaOEmbed {
    let title: String?
    let thumbnailURL: URL?
    let authorName: String?
}

struct MediaPreview {
    let title: String?
    let authorName: String?
    let thumbnail: UIImage?
}

enum MediaPreviewHelper {
    private static let imageSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 6
        config.timeoutIntervalForResource = 10
        config.urlCache = URLCache(memoryCapacity: 8 * 1024 * 1024, diskCapacity: 32 * 1024 * 1024)
        return URLSession(configuration: config)
    }()

    static func endpoint(for sourceUrl: String) -> AnalyzeEndpoint {
        pickEndpoint(sourceUrl)
    }

    static func cachedPreview(for sourceUrl: String) -> MediaPreview? {
        MediaPreviewCache.shared.preview(for: sourceUrl)
    }

    static func youtubeVideoID(from urlString: String) -> String? {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        if url.host?.contains("youtu.be") == true {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.isEmpty ? nil : id
        }
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let id = items.first(where: { $0.name == "v" })?.value, !id.isEmpty {
            return id
        }
        let path = url.path
        if path.contains("/shorts/") {
            return path.components(separatedBy: "/shorts/").last?.split(separator: "/").first.map(String.init)
        }
        if path.contains("/embed/") {
            return path.components(separatedBy: "/embed/").last?.split(separator: "/").first.map(String.init)
        }
        return nil
    }

    static func thumbnailURL(for sourceUrl: String) -> URL? {
        let endpoint = endpoint(for: sourceUrl)
        if endpoint == .youtube, let id = youtubeVideoID(from: sourceUrl) {
            return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
        }
        return nil
    }

    static func displayTitle(for entry: AnalysisHistoryEntry, videoTitle: String? = nil) -> String {
        let candidates: [String?] = [
            videoTitle,
            entry.title,
            entry.response.analysis?.summary,
            entry.response.analysis?.verdict
        ]
        for candidate in candidates {
            if let text = candidate, !text.isEmpty, !isGenericMediaTitle(text) {
                return FCTextFormat.display(text)
            }
        }
        return entry.sourceUrl
    }

    static func isGenericMediaTitle(_ text: String) -> Bool {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
        let generic = Set([
            "youtube video", "yt video", "tiktok video", "video",
            "youtube short", "yt short", "short video",
            "youtube", "tiktok", "article", "artykuł"
        ])
        if generic.contains(normalized) { return true }
        if normalized.hasPrefix("yt ") && normalized.contains("video") { return true }
        if normalized.hasPrefix("tiktok ") && normalized.contains("video") { return true }
        return false
    }

    static func isGenericMediaLabel(_ text: String) -> Bool {
        isGenericMediaTitle(text)
    }

    static func resolvedMediaTitle(
        primary: String?,
        secondary: String?,
        entry: AnalysisHistoryEntry? = nil,
        sourceUrl: String
    ) -> String? {
        for candidate in [primary, secondary] {
            if let title = candidate, !title.isEmpty, !isGenericMediaTitle(title) {
                return FCTextFormat.display(title)
            }
        }
        if let entry {
            let fallback = displayTitle(for: entry)
            if fallback != sourceUrl { return fallback }
        }
        return nil
    }

    private static func needsTitle(_ title: String?) -> Bool {
        guard let title, !title.isEmpty else { return true }
        return isGenericMediaTitle(title)
    }

    private static func isCacheComplete(_ preview: MediaPreview, endpoint: AnalyzeEndpoint) -> Bool {
        guard preview.thumbnail != nil else { return false }
        return !needsTitle(preview.title)
    }

    static func loadOEmbed(for sourceUrl: String) async -> MediaOEmbed? {
        let endpoint = endpoint(for: sourceUrl)
        switch endpoint {
        case .youtube:
            return await loadYouTubeOEmbed(for: sourceUrl)
        case .tiktok:
            return await loadNoEmbed(for: sourceUrl)
        case .article:
            return await loadNoEmbed(for: sourceUrl)
        }
    }

    private static func loadYouTubeOEmbed(for sourceUrl: String) async -> MediaOEmbed? {
        guard let encoded = sourceUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.youtube.com/oembed?url=\(encoded)&format=json") else { return nil }
        return await fetchOEmbedJSON(from: url)
    }

    private static func loadNoEmbed(for sourceUrl: String) async -> MediaOEmbed? {
        guard let encoded = sourceUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://noembed.com/embed?url=\(encoded)") else { return nil }
        return await fetchOEmbedJSON(from: url)
    }

    private static func fetchOEmbedJSON(from url: URL) async -> MediaOEmbed? {
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 6
            let (data, response) = try await imageSession.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["error"] == nil else { return nil }
            let title = (json["title"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            let thumbString = (json["thumbnail_url"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            let author = (json["author_name"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            return MediaOEmbed(
                title: title,
                thumbnailURL: thumbString.flatMap { URL(string: $0) },
                authorName: author
            )
        } catch {
            return nil
        }
    }

    static func loadLinkPresentation(for sourceUrl: String) async -> MediaPreview? {
        guard let url = URL(string: sourceUrl.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        let provider = LPMetadataProvider()
        provider.timeout = 8
        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            var thumbnail: UIImage?
            if let imageProvider = metadata.imageProvider {
                thumbnail = await loadImage(from: imageProvider)
            }
            let author = tiktokAuthorFromURL(sourceUrl)
            return MediaPreview(
                title: metadata.title,
                authorName: author,
                thumbnail: thumbnail
            )
        } catch {
            return nil
        }
    }

    /// Loads title, author and thumbnail. Uses disk cache first; YouTube skips slow LinkPresentation.
    static func loadMediaPreview(for sourceUrl: String) async -> MediaPreview {
        let endpoint = endpoint(for: sourceUrl)

        if let cached = cachedPreview(for: sourceUrl), isCacheComplete(cached, endpoint: endpoint) {
            return cached
        }

        let cached = cachedPreview(for: sourceUrl)

        var image = cached?.thumbnail
        var title = cached?.title
        var author = cached?.authorName ?? tiktokAuthorFromURL(sourceUrl)

        switch endpoint {
        case .youtube:
            if image == nil, let directURL = thumbnailURL(for: sourceUrl) {
                image = await loadImage(from: directURL, sourceUrl: sourceUrl)
            }
            if needsTitle(title) {
                if let oembed = await loadYouTubeOEmbed(for: sourceUrl) {
                    title = resolvedMediaTitle(primary: oembed.title, secondary: nil, sourceUrl: sourceUrl) ?? title
                    author = oembed.authorName ?? author
                }
            }

        case .tiktok:
            let needsThumb = image == nil
            let needsMeta = needsTitle(title)
            if needsThumb || needsMeta {
                if let link = await loadLinkPresentation(for: sourceUrl) {
                    if needsThumb, let thumb = link.thumbnail { image = thumb }
                    if needsMeta {
                        title = resolvedMediaTitle(primary: link.title, secondary: nil, sourceUrl: sourceUrl) ?? title
                    }
                    author = link.authorName ?? author
                }
            }

        case .article:
            if image == nil || needsTitle(title) {
                if let oembed = await loadNoEmbed(for: sourceUrl) {
                    if needsTitle(title) {
                        title = resolvedMediaTitle(primary: oembed.title, secondary: nil, sourceUrl: sourceUrl) ?? title
                    }
                    author = oembed.authorName ?? author
                    if image == nil, let thumbURL = oembed.thumbnailURL {
                        image = await loadImage(from: thumbURL, sourceUrl: sourceUrl)
                    }
                }
            }
        }

        let preview = MediaPreview(title: title, authorName: author, thumbnail: image)
        MediaPreviewCache.shared.store(preview, for: sourceUrl)
        return preview
    }

    static func tiktokAuthorFromURL(_ sourceUrl: String) -> String? {
        guard endpoint(for: sourceUrl) == .tiktok,
              let range = sourceUrl.range(of: #"@[\w.]+"#, options: .regularExpression) else { return nil }
        return String(sourceUrl[range])
    }

    static func loadVideoTitle(for sourceUrl: String) async -> String? {
        await loadMediaPreview(for: sourceUrl).title
    }

    static func hostLabel(for sourceUrl: String) -> String {
        guard let host = URL(string: sourceUrl)?.host else { return sourceUrl }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    static func loadThumbnail(for sourceUrl: String) async -> UIImage? {
        if let cached = MediaPreviewCache.shared.thumbnail(for: sourceUrl) { return cached }
        if let direct = thumbnailURL(for: sourceUrl),
           let image = await loadImage(from: direct, sourceUrl: sourceUrl) {
            return image
        }
        return await loadMediaPreview(for: sourceUrl).thumbnail
    }

    static func loadImage(from url: URL, sourceUrl: String? = nil) async -> UIImage? {
        if let cached = MediaPreviewCache.shared.thumbnail(for: sourceUrl ?? url.absoluteString) {
            return cached
        }
        do {
            let (data, response) = try await imageSession.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let image = UIImage(data: data) else { return nil }
            if let sourceUrl {
                MediaPreviewCache.shared.rememberImage(image, for: sourceUrl)
            }
            return image
        } catch {
            return nil
        }
    }

    private static func loadImage(from provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            guard provider.canLoadObject(ofClass: UIImage.self) else {
                continuation.resume(returning: nil)
                return
            }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                continuation.resume(returning: object as? UIImage)
            }
        }
    }
}
