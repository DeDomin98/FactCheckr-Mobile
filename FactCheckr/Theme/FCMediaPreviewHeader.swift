import SwiftUI

/// Thumbnail + title/author preview for videos, TikToks and articles during analysis and on results.
struct FCMediaPreviewHeader: View {
    let sourceUrl: String
    var entry: AnalysisHistoryEntry? = nil
    var compact: Bool = false

    @State private var thumbnail: UIImage?
    @State private var mediaTitle: String?
    @State private var authorName: String?

    private var endpoint: AnalyzeEndpoint { MediaPreviewHelper.endpoint(for: sourceUrl) }
    private var isVideo: Bool { endpoint != .article }

    init(sourceUrl: String, entry: AnalysisHistoryEntry? = nil, compact: Bool = false) {
        self.sourceUrl = sourceUrl
        self.entry = entry
        self.compact = compact

        let cached = MediaPreviewHelper.cachedPreview(for: sourceUrl)
        _thumbnail = State(initialValue: cached?.thumbnail)
        _mediaTitle = State(initialValue: cached?.title)
        _authorName = State(
            initialValue: cached?.authorName ?? MediaPreviewHelper.tiktokAuthorFromURL(sourceUrl)
        )
    }

    private var displayTitle: String? {
        if let mediaTitle, !mediaTitle.isEmpty, !MediaPreviewHelper.isGenericMediaTitle(mediaTitle) {
            return mediaTitle.fcDisplay
        }
        if let entry {
            let fallback = MediaPreviewHelper.displayTitle(for: entry)
            if fallback != sourceUrl, !MediaPreviewHelper.isGenericMediaTitle(fallback) {
                return fallback
            }
        }
        return nil
    }

    private var titleBlock: some View {
        Group {
            if let displayTitle {
                Text(displayTitle)
            } else if let authorLine {
                Text(authorLine)
            }
        }
    }

    var body: some View {
        Group {
            if compact {
                compactLayout
            } else {
                expandedLayout
            }
        }
        .task(id: sourceUrl) { await refreshPreview() }
    }

    private var compactLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnailView(height: 72, cornerRadius: 10)
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                metaRow
                titleBlock
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FCTheme.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                if displayTitle != nil, let authorLine {
                    Text(authorLine)
                        .font(.caption)
                        .foregroundStyle(FCTheme.textMuted)
                        .lineLimit(1)
                }
            }
        }
    }

    private var expandedLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            metaRow

            if isVideo, displayTitle != nil {
                Text(displayTitle!)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(FCTheme.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            thumbnailView(height: isVideo ? 156 : 132, cornerRadius: 14)

            if !isVideo, let displayTitle {
                Text(displayTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(FCTheme.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            if let authorLine {
                Text(authorLine)
                    .font(.subheadline)
                    .foregroundStyle(FCTheme.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var metaRow: some View {
        HStack(spacing: 6) {
            Text(endpoint.localizedLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(FCTheme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(FCTheme.endpointColor(endpoint).opacity(0.18))
                .clipShape(Capsule())
            Text(MediaPreviewHelper.hostLabel(for: sourceUrl))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(FCTheme.textMuted)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    private var authorLine: String? {
        guard let authorName, !authorName.isEmpty else { return nil }
        if endpoint == .tiktok {
            let handle = authorName.hasPrefix("@") ? authorName : "@\(authorName)"
            return handle.fcDisplay
        }
        return authorName.fcDisplay
    }

    private func thumbnailView(height: CGFloat, cornerRadius: CGFloat) -> some View {
        ZStack {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: headerGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay {
                        Image(systemName: endpoint == .article ? "doc.text.fill" : "play.rectangle.fill")
                            .font(.system(size: compact ? 24 : 44, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
    }

    private var headerGradient: [Color] {
        switch endpoint {
        case .youtube: return [Color(hex: 0xFF0000), Color(hex: 0x990000)]
        case .tiktok: return [Color(hex: 0xFE2C55), Color(hex: 0x25F4EE).opacity(0.6)]
        case .article: return [Color(hex: 0x6366F1), Color(hex: 0x312E81)]
        }
    }

    @MainActor
    private func refreshPreview() async {
        if thumbnail == nil, endpoint == .youtube, let url = MediaPreviewHelper.thumbnailURL(for: sourceUrl) {
            thumbnail = await MediaPreviewHelper.loadImage(from: url, sourceUrl: sourceUrl)
        }

        let preview = await MediaPreviewHelper.loadMediaPreview(for: sourceUrl)
        if let title = preview.title, !MediaPreviewHelper.isGenericMediaTitle(title) {
            mediaTitle = title
        }
        if let author = preview.authorName { authorName = author }
        if let thumb = preview.thumbnail { thumbnail = thumb }
    }
}
