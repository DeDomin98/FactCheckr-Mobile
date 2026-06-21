import Foundation

enum APIErrorMapper {
    static func message(for error: APIError) -> String {
        if let status = error.status {
            switch status {
            case 401:
                return "Zaloguj się, aby kontynuować. Nowe konto daje 5 darmowych analiz."
            case 402:
                return "Wykorzystałeś darmową analizę gościa. Utwórz konto, aby dostać 5 analiz."
            case 403:
                if error.message.lowercased().contains("verify") || error.message.lowercased().contains("email") {
                    return "Potwierdź adres e-mail przed kolejną analizą."
                }
                return "Weryfikacja bezpieczeństwa nie powiodła się. Spróbuj ponownie."
            case 422:
                if error.message.lowercased().contains("long") || error.message.lowercased().contains("30") {
                    return "Film za długi — maksymalnie 30 minut."
                }
                if error.message.lowercased().contains("speech") {
                    return "Za mało mowy w nagraniu do analizy."
                }
                return error.message
            case 502:
                return "Usługa analizy chwilowo niedostępna. Spróbuj za chwilę."
            case 504:
                return "Przekroczono limit czasu analizy. Spróbuj ponownie."
            default:
                break
            }
        }
        return error.message
    }

    static func message(for status: Int, body: String?) -> String {
        message(for: APIError(message: body ?? "Nieznany błąd", status: status))
    }
}
