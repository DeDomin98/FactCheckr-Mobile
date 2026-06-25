import Foundation

/// All user-facing strings with Polish + English values in one place.
enum LocKey {
    // Tabs
    case tabHome, tabHistory, tabAccount

    // Common
    case retry, login, send, resend, cancel, logout

    // Language
    case languageSystem, languageSection, languageHint

    // Home
    case homeTitle, homeSubtitle, homeUrlPlaceholder, paste, check
    case recentChecks, greetingPrefix, quotaRemainingFmt, verifyToAnalyze
    case verifyEmailContinue, invalidUrl

    // Auth
    case authWelcomeTitle, authChoiceSubtitle, createAccount, signIn
    case authEmailSignupSub, authEmailSigninSub, continueEmail, authTerms
    case otherMethods, segLogin, segRegister, email, password, confirmPassword
    case continueApple, continueGoogle, or, firebaseNotConfigured

    // Account
    case userFallback, analysesLocked, testerMonthlyLimit, remainingAnalyses
    case verifyToUnlock, ofAvailableFmt, totalAnalysesLabel, wholeHistory
    case planLabelText, testerAccess, earlyAccess, yourAccount, verification
    case verified, pending, appVersion, joinFmt, loggedOutSub, loginRegister
    case checkWithoutAccount, privacy, privacyPolicy, privacyText, aboutApp, aboutText

    // History
    case historySearchPlaceholder, filterFavorites, filterAll
    case addToFavorites, removeFromFavorites, deleteFromDevice
    case historyLoading, historyEmptyTitle, historyEmptyLoggedIn, historyEmptyLoggedOut
    case historyNoResults, historyNoResultsHint

    // Threat levels
    case threatCredible, threatSuspicious, threatHighRisk

    // Onboarding
    case onboardingSub, getStarted, onboardingSkip, onboardingNext
    case onboardingPage1Title, onboardingPage1Sub
    case onboardingPage2Title, onboardingPage2Sub
    case onboardingPage3Title, onboardingPage3Sub
    case splashTagline, splashLoading, back

    // Result
    case resultTitle, checkAnother, shareButton
    case secAnalysis, secClaimsEvidence, secClaims, secSummary, secIndicators, secManipulation
    case secSourceAssessment, secMissingContext, secCorrection
    case badgeGrounding, badgePipeline

    // Share report
    case shareVerdict, shareScore, shareCredibility, shareCheckedWith, shareSource
    case shareTitle, shareModeCard, shareModePDF, shareSave, shareCopy, shareSend
    case shareSaved, shareCopied, shareSaveFailed, shareCredibilityFmt
    case sharePDFPreviewTitle, sharePDFPreviewSub, sharePDFHint, sharePDFFooter

    // Verdict categories
    case verdictTrue, verdictFalse, verdictPartial, verdictInsufficient

    // Content & metrics
    case contentArticle, manipulation, confidence, confidenceAI, claimsCount, transcript
    case scoreHintHigh, scoreHintMid, scoreHintLow
    case scoreCredible, scorePartiallyCredible, scoreDoubtful
    case noSources

    // Evidence & MBFC
    case evidenceSummary, evidenceCountFmt, evidenceConfirmingFmt, evidenceContradictingFmt
    case evidenceNeutralFmt, evidenceDisclaimer
    case mbfcTitle, mbfcBias, mbfcFactual, mbfcCredibility, mbfcQuestionable

    // Report detail
    case verdictFmt, keyClaims, manipulationSignals

    // Pipeline stages
    case pipePow, pipePowVideo, pipeScraping, pipeTranscribingYT, pipeTranscribingAudio
    case pipeExtractArticle, pipeExtractVideo, pipeResearchArticle, pipeResearchVideo
    case pipeJudgeArticle, pipeJudgeVideo, pipeAnalyzing

    // Analysis stages (progress)
    case stageTranscribing, stageExtracting, stageResearching, stageJudging, stageScraping, stageAnalyzing

    // Errors
    case errUnexpectedResponse, errNoInternet, errTimeout, errNetwork

    // Shell / misc
    case logoutConfirmTitle, welcomeNameFmt, verify, accessibilityLogout
    case confirmEmailTitle, analysesLockedUntilVerify, planFmt

    // Notifications
    case notifAnalysisReadyFmt, notifNeedsAttention, notifBackgroundAuthFail, notifBackgroundFail
    case notifActionViewResult, notifActionOpenApp

    // Contextual tips
    case tipHomeTitle, tipHomeMessage, tipHistoryTitle, tipHistoryMessage, tipShareTitle, tipShareMessage

    // Share extension
    case shareExtPassing, shareExtReadFail, shareExtNoUrl, shareExtStarting, shareExtBackgroundStarted, shareExtOpenApp

    var values: (pl: String, en: String) {
        switch self {
        // Tabs
        case .tabHome: return ("Start", "Home")
        case .tabHistory: return ("Historia", "History")
        case .tabAccount: return ("Konto", "Account")

        // Common
        case .retry: return ("Spróbuj ponownie", "Try again")
        case .login: return ("Zaloguj się", "Sign in")
        case .send: return ("Wyślij", "Send")
        case .resend: return ("Wyślij ponownie", "Resend")
        case .cancel: return ("Anuluj", "Cancel")
        case .logout: return ("Wyloguj się", "Sign out")

        // Language
        case .languageSystem: return ("Systemowy", "System")
        case .languageSection: return ("Język", "Language")
        case .languageHint: return ("Wybierz język aplikacji i analiz.", "Choose the app and analysis language.")

        // Home
        case .homeTitle: return ("Sprawdź link", "Check a link")
        case .homeSubtitle: return ("Wklej URL artykułu lub link do wideo z YouTube / TikTok.",
                                    "Paste an article URL or a YouTube / TikTok video link.")
        case .homeUrlPlaceholder: return ("https://…", "https://…")
        case .paste: return ("Wklej", "Paste")
        case .check: return ("Sprawdź", "Check")
        case .recentChecks: return ("Ostatnie sprawdzenia", "Recent checks")
        case .greetingPrefix: return ("Cześć", "Hi")
        case .quotaRemainingFmt: return ("Pozostało %d z %d analiz", "%d of %d analyses left")
        case .verifyToAnalyze: return ("Potwierdź e-mail, aby analizować", "Verify email to analyze")
        case .verifyEmailContinue: return ("Potwierdź adres e-mail, aby kontynuować analizy.",
                                           "Confirm your email to keep analyzing.")
        case .invalidUrl: return ("Nieprawidłowy adres URL. Wklej link zaczynający się od https://",
                                  "Invalid URL. Paste a link starting with https://")

        // Auth
        case .authWelcomeTitle: return ("Witaj w Fact Checkr", "Welcome to Fact Checkr")
        case .authChoiceSubtitle: return ("Zaloguj się jednym dotknięciem. 5 darmowych analiz po rejestracji.",
                                          "Sign in with one tap. 5 free analyses after sign-up.")
        case .createAccount: return ("Utwórz konto", "Create account")
        case .signIn: return ("Zaloguj się", "Sign in")
        case .authEmailSignupSub: return ("Załóż konto e-mailem i hasłem.", "Create an account with email and password.")
        case .authEmailSigninSub: return ("Wpisz e-mail i hasło.", "Enter your email and password.")
        case .continueEmail: return ("Kontynuuj przez e-mail", "Continue with email")
        case .authTerms: return ("Logując się akceptujesz regulamin i politykę prywatności.",
                                 "By signing in you accept the terms and privacy policy.")
        case .otherMethods: return ("Inne metody logowania", "Other sign-in methods")
        case .segLogin: return ("Logowanie", "Sign in")
        case .segRegister: return ("Rejestracja", "Sign up")
        case .email: return ("E-mail", "Email")
        case .password: return ("Hasło", "Password")
        case .confirmPassword: return ("Potwierdź hasło", "Confirm password")
        case .continueApple: return ("Kontynuuj z Apple", "Continue with Apple")
        case .continueGoogle: return ("Kontynuuj z Google", "Continue with Google")
        case .or: return ("lub", "or")
        case .firebaseNotConfigured: return ("Firebase nie jest skonfigurowany. Dodaj GoogleService-Info.plist.",
                                             "Firebase is not configured. Add GoogleService-Info.plist.")

        // Account
        case .userFallback: return ("Użytkowniku", "there")
        case .analysesLocked: return ("Analizy zablokowane", "Analyses locked")
        case .testerMonthlyLimit: return ("Limit miesięczny testera", "Tester monthly limit")
        case .remainingAnalyses: return ("Pozostałe analizy", "Remaining analyses")
        case .verifyToUnlock: return ("Potwierdź e-mail, aby odblokować", "Verify email to unlock")
        case .ofAvailableFmt: return ("z %d dostępnych", "of %d available")
        case .totalAnalysesLabel: return ("Łącznie analiz", "Total analyses")
        case .wholeHistory: return ("cała historia", "all-time")
        case .planLabelText: return ("Plan", "Plan")
        case .testerAccess: return ("Dostęp testera", "Tester access")
        case .earlyAccess: return ("Early access", "Early access")
        case .yourAccount: return ("Twoje konto", "Your account")
        case .verification: return ("Weryfikacja", "Verification")
        case .verified: return ("Potwierdzony", "Verified")
        case .pending: return ("Oczekuje", "Pending")
        case .appVersion: return ("Wersja aplikacji", "App version")
        case .joinFmt: return ("Dołącz do %@", "Join %@")
        case .loggedOutSub: return ("Zaloguj się przez Apple, Google lub e-mail i odbierz 5 darmowych analiz. Synchronizujemy też Twoją historię.",
                                    "Sign in with Apple, Google or email and get 5 free analyses. We sync your history too.")
        case .loginRegister: return ("Zaloguj się / Zarejestruj", "Sign in / Sign up")
        case .checkWithoutAccount: return ("Sprawdź link bez konta", "Check a link without an account")
        case .privacy: return ("Prywatność", "Privacy")
        case .privacyPolicy: return ("Polityka prywatności", "Privacy policy")
        case .privacyText: return ("Wysyłamy tylko URL do analizy i dane konta (e-mail). Nie śledzimy przeglądania.",
                                   "We only send the URL to analyze and account data (email). We don't track your browsing.")
        case .aboutApp: return ("O aplikacji", "About")
        case .aboutText: return ("%@ — ochrona przed dezinformacją. Analizuj TikTok, YouTube i artykuły dzięki silnikowi AI.",
                                 "%@ — protection against disinformation. Analyze TikTok, YouTube and articles with an AI engine.")

        // History
        case .historySearchPlaceholder: return ("Szukaj w historii…", "Search history…")
        case .filterFavorites: return ("Ulubione", "Favorites")
        case .filterAll: return ("Wszystkie", "All")
        case .addToFavorites: return ("Dodaj do ulubionych", "Add to favorites")
        case .removeFromFavorites: return ("Usuń z ulubionych", "Remove from favorites")
        case .deleteFromDevice: return ("Usuń z urządzenia", "Delete from device")
        case .historyLoading: return ("Wczytuję historię…", "Loading history…")
        case .historyEmptyTitle: return ("Brak historii", "No history")
        case .historyEmptyLoggedIn: return ("Twoje sprawdzenia z konta pojawią się tutaj.",
                                            "Your account checks will appear here.")
        case .historyEmptyLoggedOut: return ("Zaloguj się, aby zobaczyć historię z konta.",
                                             "Sign in to see your account history.")
        case .historyNoResults: return ("Brak wyników", "No results")
        case .historyNoResultsHint: return ("Zmień wyszukiwanie lub filtry.", "Adjust your search or filters.")

        // Threat levels
        case .threatCredible: return ("Wiarygodne", "Credible")
        case .threatSuspicious: return ("Podejrzane", "Suspicious")
        case .threatHighRisk: return ("Wysokie ryzyko", "High risk")

        // Onboarding
        case .onboardingSub: return ("Sprawdzaj wiarygodność artykułów i filmów z YouTube oraz TikToka dzięki analizie AI.",
                                     "Check the credibility of articles and YouTube / TikTok videos with AI analysis.")
        case .getStarted: return ("Zaczynamy", "Get started")
        case .onboardingSkip: return ("Pomiń", "Skip")
        case .onboardingNext: return ("Dalej", "Next")
        case .onboardingPage1Title: return ("Fact-check w kieszeni", "Fact-check in your pocket")
        case .onboardingPage1Sub: return ("Sprawdzaj wiarygodność treści z TikToka, YouTube i artykułów dzięki analizie AI.",
                                          "Check credibility of TikTok, YouTube and articles with AI analysis.")
        case .onboardingPage2Title: return ("Wklej link i gotowe", "Paste a link, done")
        case .onboardingPage2Sub: return ("Analiza w tle, historia zsynchronizowana z kontem i pełny raport z dowodami.",
                                          "Background analysis, synced history and full evidence reports.")
        case .onboardingPage3Title: return ("Udostępniaj werdykt", "Share your verdict")
        case .onboardingPage3Sub: return ("Generuj kartę lub PDF i wysyłaj znajomym — z logo FactCheckr.",
                                          "Generate a card or PDF and share with friends — branded with FactCheckr.")
        case .splashTagline: return ("Ochrona przed dezinformacją", "Protection against disinformation")
        case .splashLoading: return ("Ładowanie…", "Loading…")
        case .back: return ("Wstecz", "Back")

        // Result
        case .resultTitle: return ("Wynik", "Result")
        case .checkAnother: return ("Sprawdź kolejny", "Check another")
        case .shareButton: return ("Udostępnij", "Share")
        case .secAnalysis: return ("Analiza", "Analysis")
        case .secClaimsEvidence: return ("Twierdzenia i dowody", "Claims & evidence")
        case .secClaims: return ("Twierdzenia", "Claims")
        case .secSummary: return ("Podsumowanie", "Summary")
        case .secIndicators: return ("Wskaźniki", "Indicators")
        case .secManipulation: return ("Techniki manipulacji", "Manipulation techniques")
        case .secSourceAssessment: return ("Ocena źródła", "Source assessment")
        case .secMissingContext: return ("Brakujący kontekst", "Missing context")
        case .secCorrection: return ("Sprostowanie", "Correction")
        case .badgeGrounding: return ("Grounding w wyszukiwarce", "Search grounding")
        case .badgePipeline: return ("3-agentowy pipeline", "3-agent pipeline")

        // Share report
        case .shareVerdict: return ("Werdykt", "Verdict")
        case .shareScore: return ("Wynik", "Score")
        case .shareCredibility: return ("Wiarygodność", "Credibility")
        case .shareCheckedWith: return ("Sprawdzone w", "Checked with")
        case .shareSource: return ("Źródło", "Source")
        case .shareTitle: return ("Udostępnij raport", "Share report")
        case .shareModeCard: return ("Karta", "Card")
        case .shareModePDF: return ("Pełny PDF", "Full PDF")
        case .shareSave: return ("Zapisz", "Save")
        case .shareCopy: return ("Kopiuj", "Copy")
        case .shareSend: return ("Wyślij", "Send")
        case .shareSaved: return ("Zapisano w Zdjęciach", "Saved to Photos")
        case .shareCopied: return ("Skopiowano", "Copied")
        case .shareSaveFailed: return ("Nie udało się zapisać", "Could not save")
        case .shareCredibilityFmt: return ("Wiarygodność: %d/100", "Credibility: %d/100")
        case .sharePDFPreviewTitle: return ("Pełny raport PDF", "Full PDF report")
        case .sharePDFPreviewSub: return ("Wszystkie sekcje, twierdzenia i źródła w jednym pliku.", "All sections, claims and sources in one file.")
        case .sharePDFHint: return ("PDF zawiera tytuł, miniaturę (YouTube), werdykt, podsumowanie, twierdzenia, wskaźniki i transkrypcję.", "PDF includes title, thumbnail (YouTube), verdict, summary, claims, indicators and transcript.")
        case .sharePDFFooter: return ("Wygenerowano w FactCheckr · factcheckrai.com", "Generated with FactCheckr · factcheckrai.com")

        // Verdict categories
        case .verdictTrue: return ("Prawda", "True")
        case .verdictFalse: return ("Fałsz", "False")
        case .verdictPartial: return ("Częściowo", "Partially true")
        case .verdictInsufficient: return ("Brak danych", "Insufficient data")

        // Content & metrics
        case .contentArticle: return ("Artykuł", "Article")
        case .manipulation: return ("Manipulacja", "Manipulation")
        case .confidence: return ("Pewność", "Confidence")
        case .confidenceAI: return ("Pewność AI", "AI confidence")
        case .claimsCount: return ("Twierdzenia", "Claims")
        case .transcript: return ("Transkrypcja", "Transcript")
        case .scoreHintHigh: return ("Wysoki wynik — większość twierdzeń potwierdzona przez niezależne źródła.",
                                     "High score — most claims confirmed by independent sources.")
        case .scoreHintMid: return ("Średni wynik — mieszane dowody: część twierdzeń potwierdzona, inne podważone lub niezweryfikowane.",
                                    "Medium score — mixed evidence: some claims confirmed, others disputed or unverified.")
        case .scoreHintLow: return ("Niski wynik — wiele twierdzeń zaprzeczonych przez niezależne źródła.",
                                    "Low score — many claims contradicted by independent sources.")
        case .scoreCredible: return ("Wiarygodne", "Credible")
        case .scorePartiallyCredible: return ("Częściowo wiarygodne", "Partially credible")
        case .scoreDoubtful: return ("Wątpliwe", "Doubtful")
        case .noSources: return ("Brak źródeł", "No sources")

        // Evidence & MBFC
        case .evidenceSummary: return ("Podsumowanie dowodów", "Evidence summary")
        case .evidenceCountFmt: return ("%d źródeł · %d twierdzeń", "%d sources · %d claims")
        case .evidenceConfirmingFmt: return ("%d potwierdza", "%d confirming")
        case .evidenceContradictingFmt: return ("%d zaprzecza", "%d contradicting")
        case .evidenceNeutralFmt: return ("%d kontekst", "%d context")
        case .evidenceDisclaimer: return ("Wyniki oparte na zebranych źródłach. Oceń sam na podstawie dowodów poniżej.",
                                          "Results based on collected sources. Judge for yourself using the evidence below.")
        case .mbfcTitle: return ("Media Bias/Fact Check", "Media Bias/Fact Check")
        case .mbfcBias: return ("Stronniczość", "Bias")
        case .mbfcFactual: return ("Faktyczność", "Factual reporting")
        case .mbfcCredibility: return ("Wiarygodność", "Credibility")
        case .mbfcQuestionable: return ("Źródło oznaczone jako wątpliwe przez MBFC", "Source flagged as questionable by MBFC")

        // Report detail
        case .verdictFmt: return ("Werdykt: %@", "Verdict: %@")
        case .keyClaims: return ("Kluczowe twierdzenia", "Key claims")
        case .manipulationSignals: return ("Sygnały manipulacji", "Manipulation signals")

        // Pipeline stages
        case .pipePow: return ("Rozwiązywanie zabezpieczenia", "Solving security challenge")
        case .pipePowVideo: return ("Weryfikacja bezpieczeństwa", "Security verification")
        case .pipeScraping: return ("Pobieranie treści strony", "Fetching page content")
        case .pipeTranscribingYT: return ("Pobieranie transkrypcji", "Fetching transcript")
        case .pipeTranscribingAudio: return ("Transkrypcja audio", "Audio transcription")
        case .pipeExtractArticle: return ("Wyodrębnianie twierdzeń", "Extracting claims")
        case .pipeExtractVideo: return ("Ekstrakcja twierdzeń", "Extracting claims")
        case .pipeResearchArticle: return ("Weryfikacja w źródłach online", "Verifying with online sources")
        case .pipeResearchVideo: return ("Weryfikacja faktów", "Fact-checking")
        case .pipeJudgeArticle: return ("Ocena wiarygodności", "Credibility assessment")
        case .pipeJudgeVideo: return ("Ocena końcowa", "Final assessment")
        case .pipeAnalyzing: return ("Analiza AI", "AI analysis")

        // Analysis stages
        case .stageTranscribing: return ("Transkrypcja", "Transcription")
        case .stageExtracting: return ("Ekstrakcja", "Extraction")
        case .stageResearching: return ("Research", "Research")
        case .stageJudging: return ("Werdykt", "Verdict")
        case .stageScraping: return ("Pobieranie strony", "Fetching page")
        case .stageAnalyzing: return ("Analiza", "Analysis")

        // Errors
        case .errUnexpectedResponse: return ("Nieoczekiwany format odpowiedzi serwera. Spróbuj ponownie.",
                                             "Unexpected server response. Try again.")
        case .errNoInternet: return ("Brak połączenia z internetem.", "No internet connection.")
        case .errTimeout: return ("Przekroczono limit czasu. Spróbuj ponownie.", "Request timed out. Try again.")
        case .errNetwork: return ("Błąd sieci. Spróbuj ponownie.", "Network error. Try again.")

        // Shell / misc
        case .logoutConfirmTitle: return ("Wylogować się?", "Sign out?")
        case .welcomeNameFmt: return ("Cześć, %@!", "Hi, %@!")
        case .verify: return ("Weryfikuj", "Verify")
        case .accessibilityLogout: return ("Wyloguj", "Sign out")
        case .confirmEmailTitle: return ("Potwierdź e-mail", "Confirm email")
        case .analysesLockedUntilVerify: return ("Analizy zablokowane do weryfikacji", "Analyses locked until verified")
        case .planFmt: return ("%@ Plan", "%@ Plan")

        // Notifications
        case .notifAnalysisReadyFmt: return ("Analiza gotowa · %@", "Analysis ready · %@")
        case .notifNeedsAttention: return ("Analiza wymaga uwagi", "Analysis needs attention")
        case .notifBackgroundAuthFail: return ("Otwórz aplikację, aby dokończyć analizę i sprawdzić limit.",
                                                "Open the app to finish the analysis and check your quota.")
        case .notifBackgroundFail: return ("Nie udało się przeanalizować w tle. Otwórz aplikację, aby spróbować ponownie.",
                                          "Background analysis failed. Open the app to try again.")
        case .notifActionViewResult: return ("Zobacz wynik", "View result")
        case .notifActionOpenApp: return ("Otwórz aplikację", "Open app")

        // Contextual tips
        case .tipHomeTitle: return ("Wklej link do analizy", "Paste a link to analyze")
        case .tipHomeMessage: return ("Skopiuj URL z TikToka, YouTube lub artykułu i wklej go tutaj — wynik pojawi się w kilka chwil.",
                                      "Copy a URL from TikTok, YouTube or an article and paste it here — results appear in moments.")
        case .tipHistoryTitle: return ("Szukaj i filtruj", "Search and filter")
        case .tipHistoryMessage: return ("Użyj wyszukiwarki, gwiazdek ulubionych i filtrów zagrożenia, aby szybko znaleźć sprawdzenia.",
                                          "Use search, favorites and threat filters to find checks quickly.")
        case .tipShareTitle: return ("Analiza w tle działa", "Background analysis works")
        case .tipShareMessage: return ("Udostępnij filmik przez Share → FactCheckr. Dostaniesz powiadomienie z przyciskiem „Zobacz wynik”.",
                                       "Share a video via Share → FactCheckr. You'll get a notification with a “View result” button.")

        // Share extension
        case .shareExtPassing: return ("Przekazuję link do Fact Checkr…", "Passing link to Fact Checkr…")
        case .shareExtReadFail: return ("Nie udało się odczytać udostępnionej treści.", "Could not read shared content.")
        case .shareExtNoUrl: return ("Nie znaleziono linku. Udostępnij post z adresem URL.", "No link found. Share a post with a URL.")
        case .shareExtStarting: return ("Uruchamiam analizę…", "Starting analysis…")
        case .shareExtBackgroundStarted: return ("Analiza ruszyła! Powiadomimy Cię, gdy będzie gotowa — możesz wrócić do filmu.",
                                                 "Analysis started! We'll notify you when it's ready — you can go back to your video.")
        case .shareExtOpenApp: return ("Otwórz aplikację Fact Checkr, aby dokończyć analizę.", "Open Fact Checkr to finish the analysis.")
        }
    }
}
