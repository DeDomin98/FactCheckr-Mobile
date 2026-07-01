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
    case deleteAccount, deleteAccountTitle, deleteAccountMessage, deleteAccountConfirm
    case deleteAccountPasswordPrompt, deleteAccountPasswordPlaceholder, deleteAccountReauth
    case deleteAccountRemoteFailed, deleteAccountNotConfigured, deleteAccountDeleting

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
    case onboardingPage4Title, onboardingPage4Sub
    case onboardingPage5Title, onboardingPage5Sub
    case onboardingPage6Title, onboardingPage6Sub
    case onboardingPage7Title, onboardingPage7Sub
    case onboardingPage1Feat1, onboardingPage1Feat2, onboardingPage1Feat3
    case onboardingPage2Feat1, onboardingPage2Feat2, onboardingPage2Feat3
    case onboardingPage7Feat1, onboardingPage7Feat2, onboardingPage7Feat3
    case onboardingPasteStep1, onboardingPasteStep2, onboardingPasteStep3
    case onboardingTikTokStep1, onboardingTikTokStep2, onboardingTikTokStep3, onboardingTikTokStep4
    case onboardingYTStep1, onboardingYTStep2, onboardingYTStep3, onboardingYTStep4
    case onboardingBackgroundStep1, onboardingBackgroundStep2, onboardingBackgroundStep3, onboardingBackgroundStep4
    case onboardingStepFmt

    // Post-login tutorial
    case postLoginWelcomeTitle, postLoginWelcomeSub, postLoginWelcomeHint
    case postLoginTokensBadge, postLoginTryDemo, postLoginPasteTitle, postLoginPasteSub
    case postLoginPasteButton, postLoginPasteFreeHint, postLoginLinkReady
    case postLoginDemoFreeTag, postLoginDemoArticleTeaser, postLoginAnalyzingTitle
    case postLoginDemoBadge, postLoginDemoBadgeSub, postLoginFinishButton
    case postLoginDemoStageScrape, postLoginDemoStageAnalyze, postLoginDemoStageVerdict

    case splashTagline, splashLoading, back

    // Result
    case resultTitle, checkAnother, shareButton
    case secAnalysis, secClaimsEvidence, secClaims, secSummary, secIndicators, secManipulation
    case secSourceAssessment, secMissingContext, secCorrection, secAllSources, secCategories
    case keyFindingsLabel, scoreReasoningLabel, sourcesUsedLabel
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
    case tipHomeTitle, tipHomeMessage, tipHistoryTitle, tipHistoryMessage
    case tipShareFavoritesTitle, tipShareFavoritesMessage
    case tipShareTitle, tipShareMessage
    case tipClipboardTitle, tipClipboardMessage, tipClipboardAction

    // Share extension
    case shareExtensionName
    case openSourceMaterial
    case shareExtPassing, shareExtReadFail, shareExtNoUrl, shareExtStarting, shareExtBackgroundStarted, shareExtOpenApp
    case shareExtNotLoggedIn, shareExtBackgroundFailed
    case bgAnalysisInflightTitle, bgAnalysisInflightMessage

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
        case .deleteAccount: return ("Usuń konto", "Delete account")
        case .deleteAccountTitle: return ("Usunąć konto na stałe?", "Delete account permanently?")
        case .deleteAccountMessage: return ("Usuniemy Twoje konto, profil, historię analiz w chmurze i dane lokalne na tym urządzeniu. Tej operacji nie można cofnąć.",
                                            "We'll delete your account, cloud profile, analysis history and local data on this device. This cannot be undone.")
        case .deleteAccountConfirm: return ("Usuń konto", "Delete account")
        case .deleteAccountPasswordPrompt: return ("Podaj hasło, aby potwierdzić usunięcie konta.", "Enter your password to confirm account deletion.")
        case .deleteAccountPasswordPlaceholder: return ("Hasło", "Password")
        case .deleteAccountReauth: return ("Ze względów bezpieczeństwa zaloguj się ponownie (wyloguj i zaloguj), a następnie spróbuj jeszcze raz.",
                                           "For security, sign in again (log out and back in), then try deleting your account once more.")
        case .deleteAccountRemoteFailed: return ("Nie udało się usunąć danych w chmurze. Sprawdź połączenie i spróbuj ponownie.",
                                                  "Could not delete cloud data. Check your connection and try again.")
        case .deleteAccountNotConfigured: return ("Usuwanie konta wymaga skonfigurowanego Firebase.", "Account deletion requires Firebase to be configured.")
        case .deleteAccountDeleting: return ("Usuwanie konta…", "Deleting account…")

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
        case .onboardingPage1Title: return ("Nie wierz wszystkiemu z scrolla", "Don't trust everything you scroll")
        case .onboardingPage1Sub: return ("Podejrzany film na TikToku albo YouTube? Wklej link albo udostępnij go do FactCheckr. Dostajesz werdykt i dowody, zamiast wierzyć na słowo.",
                                          "Suspicious TikTok or YouTube video? Paste a link or share it to FactCheckr. You get a verdict and evidence, instead of taking someone's word for it.")
        case .onboardingPage2Title: return ("Co dokładnie dostajesz?", "What do you actually get?")
        case .onboardingPage2Sub: return ("Nie tylko etykietka „prawda/fałsz”. Pełny raport jak u dziennikarza, tylko w minutę.",
                                          "Not just a true/false label. A full journalist-style report, in about a minute.")
        case .onboardingPage3Title: return ("Sposób 1: wklej link", "Method 1: paste a link")
        case .onboardingPage3Sub: return ("Masz już link w schowku? To najprostsza droga, trzy tapnięcia i masz wynik.",
                                          "Already have a link copied? Easiest path, three taps and you have a result.")
        case .onboardingPage4Title: return ("Sposób 2: Share z TikToka", "Method 2: Share from TikTok")
        case .onboardingPage4Sub: return ("Bez kopiowania linku. TikTok, Udostępnij, FactCheckr. Reszta dzieje się sama.",
                                          "No copying links. TikTok, Share, FactCheckr. The rest happens on its own.")
        case .onboardingPage5Title: return ("To samo na YouTube", "Same thing on YouTube")
        case .onboardingPage5Sub: return ("Identycznie prosto: Share pod filmem, wybierz FactCheckr, analiza startuje w tle.",
                                          "Just as simple: Share under the video, pick FactCheckr, analysis starts in the background.")
        case .onboardingPage6Title: return ("Analiza w tle, bez czekania", "Background analysis, no waiting")
        case .onboardingPage6Sub: return ("Nie musisz siedzieć w appce. Wracasz do scrollowania, a my damy znać, gdy wynik będzie gotowy.",
                                          "No need to sit in the app. Go back to scrolling, we'll notify you when the result is ready.")
        case .onboardingPage7Title: return ("Załóż konto i zaczynamy", "Create an account and go")
        case .onboardingPage7Sub: return ("Konto to historia sprawdzeń w chmurze i darmowe analizy na start. Możesz też sprawdzać bez logowania.",
                                          "Account means synced history and free analyses to start. You can also check links without signing in.")
        case .onboardingPage1Feat1: return ("TikTok, YouTube i artykuły z internetu", "TikTok, YouTube and web articles")
        case .onboardingPage1Feat2: return ("Werdykt plus dowody, nie sama opinia", "Verdict plus evidence, not just an opinion")
        case .onboardingPage1Feat3: return ("Po polsku i po angielsku", "In Polish and English")
        case .onboardingPage2Feat1: return ("Ocena wiarygodności 0-100", "Credibility score 0-100")
        case .onboardingPage2Feat2: return ("Twierdzenia z linkami do źródeł", "Claims with links to sources")
        case .onboardingPage2Feat3: return ("Wykrywanie manipulacji i brakującego kontekstu", "Manipulation and missing context detection")
        case .onboardingPage7Feat1: return ("5 darmowych analiz po rejestracji", "5 free analyses after sign-up")
        case .onboardingPage7Feat2: return ("Historia wszystkich sprawdzeń na koncie", "Full check history on your account")
        case .onboardingPage7Feat3: return ("Apple, Google lub e-mail, wybierz co lubisz", "Apple, Google or email, your choice")
        case .onboardingPasteStep1: return ("Skopiuj link do filmu lub artykułu", "Copy the link to a video or article")
        case .onboardingPasteStep2: return ("Otwórz FactCheckr i wklej link na ekranie głównym", "Open FactCheckr and paste the link on the home screen")
        case .onboardingPasteStep3: return ("Tapnij „Analizuj”, za chwilę masz pełny raport", "Tap \"Analyze\", your full report arrives in a moment")
        case .onboardingTikTokStep1: return ("Otwórz film, który chcesz sprawdzić", "Open the video you want to check")
        case .onboardingTikTokStep2: return ("Tapnij Udostępnij (strzałka w prawo)", "Tap Share (arrow on the right)")
        case .onboardingTikTokStep3: return ("Wybierz FactCheckr, przy pierwszym razie dodaj do Ulubionych", "Pick FactCheckr, on first use add it to Favorites")
        case .onboardingTikTokStep4: return ("Wróć do TikToka, analiza ruszyła w tle", "Go back to TikTok, analysis is running in the background")
        case .onboardingYTStep1: return ("Otwórz film na YouTube", "Open a video on YouTube")
        case .onboardingYTStep2: return ("Tapnij Udostępnij pod odtwarzaczem", "Tap Share below the player")
        case .onboardingYTStep3: return ("Wybierz FactCheckr z listy aplikacji", "Select FactCheckr from the app list")
        case .onboardingYTStep4: return ("Możesz oglądać dalej, analiza idzie w tle", "Keep watching, analysis runs in the background")
        case .onboardingBackgroundStep1: return ("Po Share nie musisz czekać w FactCheckr", "After Share you don't have to wait in FactCheckr")
        case .onboardingBackgroundStep2: return ("Film jest sprawdzany cicho w tle", "The video is checked quietly in the background")
        case .onboardingBackgroundStep3: return ("Dostaniesz powiadomienie: „Wynik gotowy”", "You'll get a notification: \"Result ready\"")
        case .onboardingBackgroundStep4: return ("Tapnij powiadomienie, od razu widzisz raport", "Tap the notification, the report opens instantly")
        case .onboardingStepFmt: return ("Krok %d", "Step %d")

        case .postLoginWelcomeTitle: return ("Konto gotowe!", "You're all set!")
        case .postLoginWelcomeSub: return ("Dziękujemy za dołączenie. Masz 5 darmowych analiz — wykorzystaj je na linki, które naprawdę Cię interesują.",
                                             "Thanks for joining. You have 5 free analyses — use them on links you actually care about.")
        case .postLoginWelcomeHint: return ("Na start pokażemy Ci krok po kroku, jak wkleić link i co zobaczysz w raporcie. Użyjemy prawdziwego artykułu z rp.pl.",
                                             "First we'll walk you through pasting a link and what you'll see in the report, using a real rp.pl article.")
        case .postLoginTokensBadge: return ("5 darmowych analiz na start", "5 free analyses to start")
        case .postLoginTryDemo: return ("Wypróbuj na przykładzie", "Try the example")
        case .postLoginPasteTitle: return ("Wklej link — tak jak na ekranie głównym", "Paste a link — just like on the home screen")
        case .postLoginPasteSub: return ("Tapnij „Wklej przykład” poniżej. Potem „Analizuj” — dokładnie tak zrobisz z dowolnym artykułem lub filmem.",
                                          "Tap \"Paste example\" below, then \"Analyze\" — the same flow works for any article or video.")
        case .postLoginPasteButton: return ("Wklej przykładowy link", "Paste example link")
        case .postLoginPasteFreeHint: return ("Ta analiza demo jest w 100% darmowa i nie odejmuje żadnego z Twoich 5 tokenów.",
                                                 "This demo analysis is 100% free and does not use any of your 5 tokens.")
        case .postLoginLinkReady: return ("Link w polu — gotowe do analizy", "Link in the field — ready to analyze")
        case .postLoginDemoFreeTag: return ("0 tokenów", "0 tokens")
        case .postLoginDemoArticleTeaser: return ("Wyrok Sądu Najwyższego USA w sprawie obywatelstwa z urodzenia — idealny przykład reportażu newsowego.",
                                                   "US Supreme Court ruling on birthright citizenship — a perfect sample news report.")
        case .postLoginAnalyzingTitle: return ("Analizujemy artykuł…", "Analyzing the article…")
        case .postLoginDemoBadge: return ("Przykładowa analiza", "Sample analysis")
        case .postLoginDemoBadgeSub: return ("Nie zużyła żadnego tokenu. Twoje 5 analiz czeka nietknięte.",
                                              "Used zero tokens. Your 5 analyses are still untouched.")
        case .postLoginFinishButton: return ("Przejdź do aplikacji", "Go to the app")
        case .postLoginDemoStageScrape: return ("Pobieranie treści artykułu z rp.pl…", "Fetching article content from rp.pl…")
        case .postLoginDemoStageAnalyze: return ("Sprawdzanie twierdzeń w wiarygodnych źródłach…", "Checking claims against reliable sources…")
        case .postLoginDemoStageVerdict: return ("Przygotowywanie werdyktu i raportu…", "Preparing verdict and report…")

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
        case .secAllSources: return ("Wszystkie źródła", "All sources")
        case .secCategories: return ("Kategorie", "Categories")
        case .keyFindingsLabel: return ("Kluczowe ustalenia", "Key findings")
        case .scoreReasoningLabel: return ("Uzasadnienie oceny", "Score reasoning")
        case .sourcesUsedLabel: return ("Źródła w pipeline", "Pipeline sources")
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
        case .sharePDFHint: return ("PDF zawiera pełną analizę: werdykt, wyniki, twierdzenia z dowodami, wskaźniki, manipulację, ocenę źródła i transkrypcję.",
                                      "PDF includes the full analysis: verdict, scores, claims with evidence, indicators, manipulation, source assessment and transcript.")
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
        case .scoreHintHigh: return ("Wysoki wynik, większość twierdzeń potwierdzona przez niezależne źródła.",
                                     "High score, most claims confirmed by independent sources.")
        case .scoreHintMid: return ("Średni wynik, mieszane dowody: część twierdzeń potwierdzona, inne podważone lub niezweryfikowane.",
                                    "Medium score, mixed evidence: some claims confirmed, others disputed or unverified.")
        case .scoreHintLow: return ("Niski wynik, wiele twierdzeń zaprzeczonych przez niezależne źródła.",
                                    "Low score, many claims contradicted by independent sources.")
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
        case .tipShareFavoritesTitle: return ("Dodaj do Ulubionych w TikToku", "Add to Favorites in TikTok")
        case .tipShareFavoritesMessage: return ("TikTok → Udostępnij → Więcej → Edytuj → dodaj „Analizuj TikTok” do Ulubionych — wtedy będzie na górze listy.",
                                                 "TikTok → Share → More → Edit → add “Analyze TikTok” to Favorites — it will appear at the top.")
        case .tipShareTitle: return ("Analiza w tle działa", "Background analysis works")
        case .tipShareMessage: return ("Udostępnij filmik przez Share → Analizuj TikTok. Dostaniesz powiadomienie z przyciskiem „Zobacz wynik”.",
                                       "Share a video via Share → Analyze TikTok. You'll get a notification with a “View result” button.")
        case .tipClipboardTitle: return ("Link TikToka w schowku", "TikTok link in clipboard")
        case .tipClipboardMessage: return ("Skopiowałeś link z TikToka — wklej go jednym tapnięciem.",
                                           "You copied a TikTok link — paste it with one tap.")
        case .tipClipboardAction: return ("Wklej link", "Paste link")

        // Share extension
        case .shareExtensionName: return ("Analizuj TikTok", "Analyze TikTok")
        case .openSourceMaterial: return ("Otwórz oryginalny materiał", "Open original material")
        case .shareExtPassing: return ("Przekazuję link do Fact Checkr…", "Passing link to Fact Checkr…")
        case .shareExtReadFail: return ("Nie udało się odczytać udostępnionej treści.", "Could not read shared content.")
        case .shareExtNoUrl: return ("Nie znaleziono linku. Udostępnij post z adresem URL.", "No link found. Share a post with a URL.")
        case .shareExtStarting: return ("Uruchamiam analizę…", "Starting analysis…")
        case .shareExtBackgroundStarted: return ("Analiza ruszyła! Powiadomimy Cię, gdy będzie gotowa — możesz wrócić do filmu.",
                                                 "Analysis started! We'll notify you when it's ready — you can go back to your video.")
        case .shareExtOpenApp: return ("Otwórz aplikację Fact Checkr, aby dokończyć analizę.", "Open Fact Checkr to finish the analysis.")
        case .shareExtNotLoggedIn: return ("Zaloguj się w FactCheckr, aby analizować z TikToka. Otwieramy aplikację…",
                                           "Sign in to FactCheckr to analyze from TikTok. Opening the app…")
        case .shareExtBackgroundFailed: return ("Nie udało się uruchomić analizy w tle. Otwieramy aplikację…",
                                                 "Couldn't start background analysis. Opening the app…")
        case .bgAnalysisInflightTitle: return ("Analiza w tle", "Analysis in background")
        case .bgAnalysisInflightMessage: return ("Ten link jest już sprawdzany w tle. Dostaniesz powiadomienie, gdy wynik będzie gotowy — możesz wrócić do filmu.",
                                                  "This link is already being checked in the background. You'll get a notification when it's ready — you can go back to your video.")
        }
    }
}
