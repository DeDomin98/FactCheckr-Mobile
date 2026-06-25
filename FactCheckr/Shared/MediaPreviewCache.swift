import CryptoKit
import UIKit

struct CachedMediaPreviewRecord: Codable {
    let title: String?
    let authorName: String?
    let cachedAt: Date
}

/// Disk + memory cache for link thumbnails and titles keyed by source URL.
final class MediaPreviewCache {
    static let shared = MediaPreviewCache()

    private let memoryImages = NSCache<NSString, UIImage>()
    private let metadataURL: URL
    private let thumbsDir: URL
    private var records: [String: CachedMediaPreviewRecord] = [:]
    private let lock = NSLock()

    private init() {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroupConfig.identifier)
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let root = base.appendingPathComponent("media-preview-cache", isDirectory: true)
        thumbsDir = root.appendingPathComponent("thumbs", isDirectory: true)
        metadataURL = root.appendingPathComponent("metadata.json")
        try? FileManager.default.createDirectory(at: thumbsDir, withIntermediateDirectories: true)
        loadMetadata()
    }

    func preview(for sourceUrl: String) -> MediaPreview? {
        let key = cacheKey(for: sourceUrl)
        lock.lock()
        let record = records[key]
        lock.unlock()
        guard let record else { return nil }

        let thumb = thumbnail(forKey: key) ?? memoryImages.object(forKey: key as NSString)
        guard thumb != nil || record.title != nil || record.authorName != nil else { return nil }
        return MediaPreview(title: record.title, authorName: record.authorName, thumbnail: thumb)
    }

    func thumbnail(for sourceUrl: String) -> UIImage? {
        let key = cacheKey(for: sourceUrl)
        if let mem = memoryImages.object(forKey: key as NSString) { return mem }
        return thumbnail(forKey: key)
    }

    func store(_ preview: MediaPreview, for sourceUrl: String) {
        let key = cacheKey(for: sourceUrl)

        lock.lock()
        let existing = records[key]
        lock.unlock()

        let merged = MediaPreview(
            title: preview.title ?? existing?.title,
            authorName: preview.authorName ?? existing?.authorName,
            thumbnail: preview.thumbnail
        )

        let hasTitle = merged.title.map { !$0.isEmpty } ?? false
        let hasAuthor = merged.authorName.map { !$0.isEmpty } ?? false
        guard merged.thumbnail != nil || hasTitle || hasAuthor else { return }

        if let image = merged.thumbnail {
            memoryImages.setObject(image, forKey: key as NSString)
            if let data = image.jpegData(compressionQuality: 0.82) {
                try? data.write(to: thumbPath(forKey: key), options: .atomic)
            }
        }

        lock.lock()
        records[key] = CachedMediaPreviewRecord(
            title: merged.title,
            authorName: merged.authorName,
            cachedAt: Date()
        )
        lock.unlock()
        persistMetadata()
    }

    func storeThumbnail(_ image: UIImage, for sourceUrl: String) {
        store(MediaPreview(title: nil, authorName: nil, thumbnail: image), for: sourceUrl)
    }

    func rememberImage(_ image: UIImage, for sourceUrl: String) {
        let key = cacheKey(for: sourceUrl)
        memoryImages.setObject(image, forKey: key as NSString)
    }

    private func cacheKey(for sourceUrl: String) -> String {
        fileKey(for: sourceUrl.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }

    private func fileKey(for sourceUrl: String) -> String {
        let digest = SHA256.hash(data: Data(sourceUrl.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func thumbPath(forKey key: String) -> URL {
        thumbsDir.appendingPathComponent("\(key).jpg")
    }

    private func thumbnail(forKey key: String) -> UIImage? {
        let path = thumbPath(forKey: key)
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }

    private func loadMetadata() {
        guard let data = try? Data(contentsOf: metadataURL),
              let decoded = try? JSONDecoder().decode([String: CachedMediaPreviewRecord].self, from: data) else { return }
        records = decoded
    }

    private func persistMetadata() {
        lock.lock()
        let snapshot = records
        lock.unlock()
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: metadataURL, options: .atomic)
    }
}
