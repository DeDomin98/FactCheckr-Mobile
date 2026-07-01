import Foundation
import UserNotifications

extension Notification.Name {
    static let fcOpenAnalysisResult = Notification.Name("fc.openAnalysisResult")
    static let fcOpenPendingURL = Notification.Name("fc.openPendingURL")
}

/// Routes the user from a notification tap / action into the correct screen.
enum NotificationDeepLinkStore {
    private static let kindKey = "fc_notif_kind"
    private static let entryIdKey = "fc_notif_entry_id"
    private static let uidKey = "fc_notif_uid"
    private static let urlKey = "fc_notif_url"

    enum Kind: String {
        case ready
        case failed
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConfig.identifier)
    }

    static func saveReady(entryId: String, uid: String, sourceUrl: String? = nil) {
        defaults?.set(Kind.ready.rawValue, forKey: kindKey)
        defaults?.set(entryId, forKey: entryIdKey)
        defaults?.set(uid, forKey: uidKey)
        if let sourceUrl {
            defaults?.set(sourceUrl, forKey: urlKey)
        } else {
            defaults?.removeObject(forKey: urlKey)
        }
    }

    static func saveFailed(url: String) {
        defaults?.set(Kind.failed.rawValue, forKey: kindKey)
        defaults?.set(url, forKey: urlKey)
        defaults?.removeObject(forKey: entryIdKey)
        defaults?.removeObject(forKey: uidKey)
    }

    static func peekReady() -> (entryId: String, uid: String, sourceUrl: String?)? {
        guard defaults?.string(forKey: kindKey) == Kind.ready.rawValue,
              let entryId = defaults?.string(forKey: entryIdKey),
              let uid = defaults?.string(forKey: uidKey) else { return nil }
        let sourceUrl = defaults?.string(forKey: urlKey)
        return (entryId, uid, sourceUrl)
    }

    static func consumeFailedURL() -> String? {
        guard defaults?.string(forKey: kindKey) == Kind.failed.rawValue,
              let url = defaults?.string(forKey: urlKey) else { return nil }
        clear()
        return url
    }

    static func clear() {
        defaults?.removeObject(forKey: kindKey)
        defaults?.removeObject(forKey: entryIdKey)
        defaults?.removeObject(forKey: uidKey)
        defaults?.removeObject(forKey: urlKey)
    }
}

enum NotificationService {
    static let categoryReady = "FC_ANALYSIS_READY"
    static let categoryFailed = "FC_ANALYSIS_FAILED"
    static let actionViewResult = "FC_VIEW_RESULT"
    static let actionOpenApp = "FC_OPEN_APP"

    private static var didRegisterCategories = false

    // MARK: - Setup

    static func registerCategoriesIfNeeded() {
        guard !didRegisterCategories else { return }
        didRegisterCategories = true

        let viewResult = UNNotificationAction(
            identifier: actionViewResult,
            title: Loc.t(.notifActionViewResult),
            options: [.foreground]
        )
        let openApp = UNNotificationAction(
            identifier: actionOpenApp,
            title: Loc.t(.notifActionOpenApp),
            options: [.foreground]
        )

        let ready = UNNotificationCategory(
            identifier: categoryReady,
            actions: [viewResult],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        let failed = UNNotificationCategory(
            identifier: categoryFailed,
            actions: [openApp],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([ready, failed])
    }

    static func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        registerCategoriesIfNeeded()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    /// Shows the system notification prompt only when status is still undecided.
    static func requestAuthorizationIfNeeded(completion: ((Bool) -> Void)? = nil) {
        registerCategoriesIfNeeded()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                requestAuthorization(completion: completion)
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async { completion?(true) }
            default:
                DispatchQueue.main.async { completion?(false) }
            }
        }
    }

    static func refreshAuthorization() {
        didRegisterCategories = false
        registerCategoriesIfNeeded()
    }

    // MARK: - Post

    static func postAnalysisReady(entry: AnalysisHistoryEntry, uid: String) {
        registerCategoriesIfNeeded()
        syncLanguageFromAppGroup()

        let content = UNMutableNotificationContent()
        content.title = String(format: Loc.t(.notifAnalysisReadyFmt), entry.threatLevel.localizedLabel)
        content.body = MediaPreviewHelper.displayTitle(for: entry)
        content.sound = .default
        content.categoryIdentifier = categoryReady
        content.threadIdentifier = "factcheckr-analysis"
        content.userInfo = [
            "kind": NotificationDeepLinkStore.Kind.ready.rawValue,
            "entryId": entry.id,
            "uid": uid,
            "sourceUrl": entry.sourceUrl
        ]

        let request = UNNotificationRequest(
            identifier: "analysis-ready-\(entry.id)",
            content: content,
            trigger: nil
        )
        deliver(request)
    }

    static func postAnalysisFailed(url: String, message: String) {
        registerCategoriesIfNeeded()
        syncLanguageFromAppGroup()

        let content = UNMutableNotificationContent()
        content.title = Loc.t(.notifNeedsAttention)
        content.body = message
        content.sound = .default
        content.categoryIdentifier = categoryFailed
        content.threadIdentifier = "factcheckr-analysis"
        content.userInfo = [
            "kind": NotificationDeepLinkStore.Kind.failed.rawValue,
            "sourceUrl": url
        ]

        let request = UNNotificationRequest(
            identifier: "analysis-failed-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        deliver(request)
    }

    private static func deliver(_ request: UNNotificationRequest) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                UNUserNotificationCenter.current().add(request) { error in
                    #if DEBUG
                    if let error {
                        print("[NotificationService] add failed: \(error.localizedDescription)")
                    }
                    #endif
                }
            default:
                #if DEBUG
                print("[NotificationService] skipped — authorization: \(settings.authorizationStatus.rawValue)")
                #endif
            }
        }
    }

    // MARK: - Handle response (AppDelegate)

    static func handleResponse(_ response: UNNotificationResponse) {
        let info = response.notification.request.content.userInfo
        let action = response.actionIdentifier

        if action == UNNotificationDismissActionIdentifier { return }

        if let kind = info["kind"] as? String, kind == NotificationDeepLinkStore.Kind.ready.rawValue,
           let entryId = info["entryId"] as? String,
           let uid = info["uid"] as? String {
            if action == UNNotificationDefaultActionIdentifier || action == actionViewResult {
                let sourceUrl = info["sourceUrl"] as? String
                NotificationDeepLinkStore.saveReady(entryId: entryId, uid: uid, sourceUrl: sourceUrl)
                NotificationCenter.default.post(name: .fcOpenAnalysisResult, object: nil, userInfo: info)
            }
            return
        }

        if let kind = info["kind"] as? String, kind == NotificationDeepLinkStore.Kind.failed.rawValue,
           let url = info["sourceUrl"] as? String {
            if action == UNNotificationDefaultActionIdentifier || action == actionOpenApp {
                SharedLinkStore.savePendingURL(url)
                NotificationDeepLinkStore.saveFailed(url: url)
                NotificationCenter.default.post(name: .fcOpenPendingURL, object: nil)
            }
        }
    }

    private static func syncLanguageFromAppGroup() {
        if let code = UserDefaults(suiteName: AppGroupConfig.identifier)?.string(forKey: "fc_app_lang_code") {
            Loc.currentCode = code
        }
    }
}
