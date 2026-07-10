import Foundation

enum APIErrorMapper {
    static func message(for error: APIError) -> String {
        if let status = error.status {
            switch status {
            case 401:
                return Loc.t(.errLoginRequired)
            case 402:
                return Loc.t(.errGuestQuota)
            case 403:
                if error.message.lowercased().contains("verify") || error.message.lowercased().contains("email") {
                    return Loc.t(.errVerifyEmail)
                }
                return Loc.t(.errSecurityCheck)
            case 422:
                if error.message.lowercased().contains("long") || error.message.lowercased().contains("30") {
                    return Loc.t(.errVideoTooLong)
                }
                if error.message.lowercased().contains("speech") {
                    return Loc.t(.errTooLittleSpeech)
                }
                return error.message
            case 502:
                return Loc.t(.errServiceUnavailable)
            case 504:
                return Loc.t(.errAnalysisTimeout)
            default:
                break
            }
        }
        return error.message
    }

    static func message(for status: Int, body: String?) -> String {
        message(for: APIError(message: body ?? Loc.t(.errUnknown), status: status))
    }
}
