import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BackgroundAnalysisService.shared.activate()
        UNUserNotificationCenter.current().delegate = self
        NotificationService.requestAuthorization()
        return true
    }

    /// The system relaunches the app here when a background analysis transfer that
    /// was started by the share extension finishes.
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        guard identifier == BackgroundAnalysisService.sessionIdentifier else {
            completionHandler()
            return
        }
        BackgroundAnalysisService.shared.backgroundCompletionHandler = completionHandler
        BackgroundAnalysisService.shared.activate()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationService.handleResponse(response)
        completionHandler()
    }
}
