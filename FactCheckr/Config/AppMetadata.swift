import Foundation

enum AppMetadata {
    static let displayName = "Fact Checkr"
    static let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let fullVersion = "\(bundleVersion) (\(buildNumber))"
}
