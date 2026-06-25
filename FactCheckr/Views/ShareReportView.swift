import SwiftUI
import UIKit
import Photos

// MARK: - Branded share card (live preview + image export)

struct ShareReportCardView: View {
    let entry: AnalysisHistoryEntry
    var thumbnail: UIImage?
    var videoTitle: String?

    private var analysis: AnalysisResult? { entry.response.analysis }
    private var category: VerdictCategory { VerdictCategory.from(analysis: analysis) }
    private var score: Int { analysis?.credibilityScore ?? entry.overallScore }
    private var endpoint: AnalyzeEndpoint { MediaPreviewHelper.endpoint(for: entry.sourceUrl) }
    private var isVideo: Bool { endpoint != .article }

    private var title: String {
        let raw: String
        if isVideo, let videoTitle, !videoTitle.isEmpty, !MediaPreviewHelper.isGenericMediaTitle(videoTitle) {
            raw = videoTitle
        } else {
            raw = MediaPreviewHelper.displayTitle(for: entry)
        }
        return raw.fcDisplay
    }

    private var summary: String {
        let text = analysis?.summary ?? analysis?.assessmentText ?? title
        let clipped = text.count > 180 ? String(text.prefix(180)) + "…" : text
        return clipped.fcDisplay
    }

    var body: some View {
        VStack(spacing: 0) {
            mediaHeader
            contentSection
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.18), .white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: category.color.opacity(0.25), radius: 24, y: 12)
    }

    private var mediaHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                platformBadge
                Text(MediaPreviewHelper.hostLabel(for: entry.sourceUrl))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            if isVideo {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

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
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }
                }
            }
            .frame(height: isVideo ? 156 : 132)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )

            if !isVideo {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
    }

    private var platformBadge: some View {
        Text(endpoint.localizedLabel)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.18))
            .clipShape(Capsule())
    }

    private var headerGradient: [Color] {
        switch endpoint {
        case .youtube: return [Color(hex: 0xFF0000), Color(hex: 0x990000)]
        case .tiktok: return [Color(hex: 0xFE2C55), Color(hex: 0x25F4EE).opacity(0.6)]
        case .article: return [Color(hex: 0x6366F1), Color(hex: 0x312E81)]
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                scoreRing
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.t(.shareVerdict).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(.white.opacity(0.45))
                    Text(category.localizedLabel)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(category.color)
                        .clipShape(Capsule())
                    Text(String(format: Loc.t(.shareCredibilityFmt), score))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer(minLength: 0)
            }

            Text(summary)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.82))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                Text(AppMetadata.displayName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text("factcheckrai.com")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xA29BFE))
            }
            .padding(.top, 4)
        }
        .padding(18)
    }

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(category.color.opacity(0.2), lineWidth: 7)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(category.color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("/100")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .frame(width: 88, height: 88)
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [Color(hex: 0x161622), Color(hex: 0x0B0B12)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

enum ShareReportRenderer {
    @MainActor
    static func makeImage(for entry: AnalysisHistoryEntry, thumbnail: UIImage? = nil, videoTitle: String? = nil) -> UIImage? {
        let view = ShareReportCardView(entry: entry, thumbnail: thumbnail, videoTitle: videoTitle)
            .frame(width: 340)
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

// MARK: - PDF export

enum ShareReportPDFBuilder {
    static func makePDF(for entry: AnalysisHistoryEntry, thumbnail: UIImage? = nil, videoTitle: String? = nil) -> URL? {
        let analysis = entry.response.analysis
        let category = VerdictCategory.from(analysis: analysis)
        let score = analysis?.credibilityScore ?? entry.overallScore
        let title = MediaPreviewHelper.displayTitle(for: entry, videoTitle: videoTitle)
        let endpoint = MediaPreviewHelper.endpoint(for: entry.sourceUrl)

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let margin: CGFloat = 44
        let contentWidth = pageRect.width - margin * 2
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            var y = margin

            func newPageIfNeeded(_ needed: CGFloat) {
                if y + needed > pageRect.height - margin {
                    context.beginPage()
                    y = margin
                }
            }

            func drawTitle(_ text: String, size: CGFloat = 18) {
                newPageIfNeeded(size + 12)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: size, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                let rect = CGRect(x: margin, y: y, width: contentWidth, height: 9999)
                let h = text.boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs,
                    context: nil
                ).height
                text.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: ceil(h)), withAttributes: attrs)
                y += ceil(h) + 10
            }

            func drawSection(_ heading: String, content: String) {
                guard !content.isEmpty else { return }
                drawTitle(heading, size: 14)
                newPageIfNeeded(40)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.darkGray
                ]
                let h = content.boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs,
                    context: nil
                ).height
                content.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: ceil(h)), withAttributes: attrs)
                y += ceil(h) + 16
            }

            context.beginPage()

            // Header bar
            let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 72)
            UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1).setFill()
            UIBezierPath(rect: headerRect).fill()
            let brand = AppMetadata.displayName
            let brandAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
            brand.draw(at: CGPoint(x: margin, y: 24), withAttributes: brandAttrs)
            let dateStr = DateFormatter.localizedString(from: entry.createdAt, dateStyle: .medium, timeStyle: .short)
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ]
            dateStr.draw(at: CGPoint(x: pageRect.width - margin - 120, y: 28), withAttributes: dateAttrs)
            y = 88

            if let thumbnail {
                let imgW = contentWidth
                let imgH = min(180, imgW * 9 / 16)
                newPageIfNeeded(imgH + 16)
                thumbnail.draw(in: CGRect(x: margin, y: y, width: imgW, height: imgH))
                y += imgH + 14
            }

            drawTitle(title, size: 20)
            drawSection(Loc.t(.shareSource), content: "\(endpoint.localizedLabel) · \(entry.sourceUrl)")

            let scoreBlock = """
            \(Loc.t(.shareCredibility)): \(score)/100
            \(Loc.t(.shareVerdict)): \(category.localizedLabel)
            """
            drawSection(Loc.t(.shareScore), content: scoreBlock)

            if let summary = analysis?.summary, !summary.isEmpty {
                drawSection(Loc.t(.secSummary), content: summary)
            }
            if let assessment = analysis?.assessmentText, !assessment.isEmpty {
                drawSection(Loc.t(.secAnalysis), content: assessment)
            }
            if let claims = analysis?.claims, !claims.isEmpty {
                let body = claims.enumerated().map { idx, c in
                    var line = "\(idx + 1). \(c.claim)"
                    if let verdict = c.verdict ?? c.status { line += " [\(verdict)]" }
                    if let reason = c.reason { line += "\n   \(reason)" }
                    return line
                }.joined(separator: "\n\n")
                drawSection(Loc.t(.secClaimsEvidence), content: body)
            }
            if let indicators = analysis?.indicators, !indicators.isEmpty {
                let body = indicators.map { "• \($0.label): \($0.detail ?? "")" }.joined(separator: "\n")
                drawSection(Loc.t(.secIndicators), content: body)
            }
            if let missing = analysis?.missingContext, !missing.isEmpty {
                drawSection(Loc.t(.secMissingContext), content: missing.map { "• \($0)" }.joined(separator: "\n"))
            }
            if let corrected = analysis?.correctedInfo, !corrected.isEmpty {
                drawSection(Loc.t(.secCorrection), content: corrected)
            }
            if let transcript = entry.response.transcript, !transcript.isEmpty {
                drawSection(Loc.t(.transcript), content: transcript)
            }

            newPageIfNeeded(30)
            let footer = Loc.t(.sharePDFFooter)
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.gray
            ]
            footer.draw(in: CGRect(x: margin, y: pageRect.height - margin - 20, width: contentWidth, height: 20), withAttributes: footerAttrs)
        }

        let fileName = "FactCheckr-\(entry.id.prefix(8)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

// MARK: - Binance-style share sheet

enum ShareExportMode: String, CaseIterable, Identifiable {
    case card
    case pdf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .card: return Loc.t(.shareModeCard)
        case .pdf: return Loc.t(.shareModePDF)
        }
    }
}

struct ShareReportSheet: View {
    let entry: AnalysisHistoryEntry
    @Environment(\.dismiss) private var dismiss

    @State private var mode: ShareExportMode = .card
    @State private var thumbnail: UIImage?
    @State private var videoTitle: String?
    @State private var renderedImage: UIImage?
    @State private var pdfURL: URL?
    @State private var isPreparing = true
    @State private var toast: String?
    @State private var showActivity = false
    @State private var activityItems: [Any] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modePicker
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        previewArea
                        if mode == .pdf {
                            pdfInfoCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }

                quickActions
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(.ultraThinMaterial)
            }
            .background(FCBackground().ignoresSafeArea())
            .navigationTitle(Loc.t(.shareTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(FCTheme.textMuted)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.82))
                        .clipShape(Capsule())
                        .padding(.bottom, 110)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35), value: toast)
            .sheet(isPresented: $showActivity) {
                ActivityView(items: activityItems)
                    .presentationDetents([.medium, .large])
            }
        }
        .task { await prepareAssets() }
        .onChange(of: mode) { _ in Task { await prepareAssets() } }
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(ShareExportMode.allCases) { item in
                Button {
                    Haptics.selection()
                    mode = item
                } label: {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(mode == item ? .white : FCTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            mode == item
                                ? AnyShapeStyle(FCTheme.accent)
                                : AnyShapeStyle(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .background(FCTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var previewArea: some View {
        if isPreparing {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(FCTheme.bgCard)
                .frame(height: mode == .card ? 420 : 360)
                .overlay { ProgressView().tint(FCTheme.accent) }
        } else if mode == .card {
            ShareReportCardView(entry: entry, thumbnail: thumbnail, videoTitle: videoTitle)
                .padding(.horizontal, 4)
                .scaleEffect(0.98)
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .frame(height: 360)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.richtext.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(FCTheme.accent)
                        Text(Loc.t(.sharePDFPreviewTitle))
                            .font(.headline)
                            .foregroundStyle(.black)
                        Text(Loc.t(.sharePDFPreviewSub))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
        }
    }

    private var pdfInfoCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(FCTheme.accentLight)
            Text(Loc.t(.sharePDFHint))
                .font(.caption)
                .foregroundStyle(FCTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }

    private var quickActions: some View {
        HStack(spacing: 0) {
            actionButton(icon: "square.and.arrow.down", title: Loc.t(.shareSave), enabled: !isPreparing) {
                saveCurrent()
            }
            actionButton(icon: "doc.on.doc", title: Loc.t(.shareCopy), enabled: !isPreparing) {
                copyCurrent()
            }
            actionButton(icon: "square.and.arrow.up", title: Loc.t(.shareSend), enabled: !isPreparing) {
                shareCurrent()
            }
        }
    }

    private func actionButton(icon: String, title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(FCTheme.bgCard)
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(enabled ? FCTheme.accentLight : FCTheme.textMuted)
                }
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(enabled ? FCTheme.textPrimary : FCTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    @MainActor
    private func prepareAssets() async {
        if let cached = MediaPreviewHelper.cachedPreview(for: entry.sourceUrl) {
            thumbnail = cached.thumbnail ?? thumbnail
            videoTitle = cached.title ?? videoTitle
            if cached.thumbnail != nil {
                renderedImage = ShareReportRenderer.makeImage(for: entry, thumbnail: thumbnail, videoTitle: videoTitle)
                pdfURL = ShareReportPDFBuilder.makePDF(for: entry, thumbnail: thumbnail, videoTitle: videoTitle)
                isPreparing = false
            }
        } else {
            isPreparing = true
        }

        let preview = await MediaPreviewHelper.loadMediaPreview(for: entry.sourceUrl)
        thumbnail = preview.thumbnail ?? thumbnail
        if let title = preview.title, !MediaPreviewHelper.isGenericMediaTitle(title) {
            videoTitle = title
        }
        renderedImage = ShareReportRenderer.makeImage(for: entry, thumbnail: thumbnail, videoTitle: videoTitle)
        pdfURL = ShareReportPDFBuilder.makePDF(for: entry, thumbnail: thumbnail, videoTitle: videoTitle)
        isPreparing = false
    }

    private func saveCurrent() {
        Haptics.impact(.medium)
        switch mode {
        case .card:
            guard let renderedImage else { return }
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else { return }
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: renderedImage)
                } completionHandler: { ok, _ in
                    Task { @MainActor in
                        showToast(ok ? Loc.t(.shareSaved) : Loc.t(.shareSaveFailed))
                    }
                }
            }
        case .pdf:
            guard let pdfURL else { return }
            shareItems([pdfURL])
        }
    }

    private func copyCurrent() {
        Haptics.impact(.light)
        switch mode {
        case .card:
            guard let renderedImage else { return }
            UIPasteboard.general.image = renderedImage
            showToast(Loc.t(.shareCopied))
        case .pdf:
            guard let pdfURL else { return }
            UIPasteboard.general.url = pdfURL
            showToast(Loc.t(.shareCopied))
        }
    }

    private func shareCurrent() {
        Haptics.impact(.light)
        switch mode {
        case .card:
            guard let renderedImage else { return }
            shareItems([renderedImage, entry.sourceUrl])
        case .pdf:
            guard let pdfURL else { return }
            shareItems([pdfURL, entry.sourceUrl])
        }
    }

    private func shareItems(_ items: [Any]) {
        activityItems = items
        showActivity = true
    }

    private func showToast(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if toast == message { toast = nil }
        }
    }
}

/// UIActivityViewController wrapper for SwiftUI sheets.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
