import Foundation

enum APIConfig {
    static let baseURL = "https://europe-central2-factcheckr-e33da.cloudfunctions.net/api"
    static let appURL = "https://factcheckrai.com"
    static let privacyURL = "https://factcheckrai.com/privacy-policy"
    static let articleModel = "gemini-3.1-flash-lite-preview"

    static var websiteURL: URL { URL(string: appURL) ?? URL(fileURLWithPath: "/") }
    static var privacyPolicyURL: URL { URL(string: privacyURL) ?? websiteURL }
}
