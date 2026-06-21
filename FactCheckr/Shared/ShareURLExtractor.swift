import Foundation
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif

enum ShareURLExtractor {
    static func extractSharedURL(from items: [NSExtensionItem]) async -> String? {
        for item in items {
            if let text = item.attributedContentText?.string,
               let url = extractURL(from: text) {
                return url
            }

            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if let url = await loadURL(from: provider) {
                    return url
                }
            }
        }
        return nil
    }

    private static func loadURL(from provider: NSItemProvider) async -> String? {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let item = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) {
                if let url = item as? URL {
                    return url.absoluteString
                }
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    return url.absoluteString
                }
            }
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let item = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier),
               let text = item as? String,
               let url = extractURL(from: text) {
                return url
            }
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            if let item = try? await provider.loadItem(forTypeIdentifier: UTType.text.identifier),
               let text = item as? String,
               let url = extractURL(from: text) {
                return url
            }
        }

        return nil
    }
}

#if canImport(UIKit)
extension ShareURLExtractor {
    static func extractSharedURL(from items: [Any]) async -> String? {
        guard let extensionItems = items as? [NSExtensionItem] else { return nil }
        return await extractSharedURL(from: extensionItems)
    }
}
#endif
