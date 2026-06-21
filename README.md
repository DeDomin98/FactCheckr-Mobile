# Fact Checkr iOS

Natywna aplikacja iOS (Swift + SwiftUI) do weryfikacji treści z TikToka, YouTube i artykułów.

## Wymagania

- macOS z Xcode 16+
- iOS 16.0+ (symulator lub urządzenie)
- Apple Developer Program (TestFlight / App Store)

## Konfiguracja Firebase (wymagana do logowania)

1. Wejdź w [Firebase Console](https://console.firebase.google.com) → projekt **factcheckr-e33da**.
2. Project settings → **Your apps** → **Add app** → **iOS**.
3. **Bundle ID:** `com.factcheckr.ios` (identyczny z Xcode).
4. Pobierz **`GoogleService-Info.plist`** i dodaj do targetu **FactCheckr** (`Resources/`).
5. Authentication → Sign-in method → włącz **Email/Password**.

> Plik `GoogleService-Info.plist` jest w `.gitignore` — każdy developer dodaje go lokalnie.

Aplikacja **kompiluje się bez** plist — wtedy auth jest wyłączony, ale analiza gościa działa.

## App Groups (Share Extension)

Oba targety używają `group.com.factcheckr.ios`:

| Target | Bundle ID |
|--------|-----------|
| FactCheckr | `com.factcheckr.ios` |
| FactCheckrShare | `com.factcheckr.ios.ShareExtension` |

W [Apple Developer](https://developer.apple.com/account/resources/identifiers/list):

1. Utwórz **App Group**: `group.com.factcheckr.ios`.
2. Włącz App Groups na obu App ID powyżej.
3. Odśwież provisioning profiles w Xcode (**Signing & Capabilities**).

## Udostępnianie z TikToka / YouTube

1. Zbuduj i zainstaluj na **fizycznym iPhone** (Share Extension na symulatorze bywa niestabilna).
2. TikTok → **Udostępnij** → **Fact Checkr**.
3. Extension zapisuje URL w App Group i otwiera appkę (`factcheckr://analyze`).
4. Główna appka **konsumuje** URL z App Group i uruchamia analizę (bez powtórki po restarcie).

> Brak na liście Share: zrestartuj iPhone albo Share Sheet → **Edytuj** → włącz Fact Checkr.

## TestFlight (live testy)

1. **Archive:** Xcode → Product → Archive (scheme **FactCheckr**, Release, urządzenie „Any iOS Device”).
2. **Upload:** Organizer → Distribute App → App Store Connect.
3. **App Store Connect:** nowa app, bundle `com.factcheckr.ios`, wersja `1.0 (2)`.
4. **TestFlight:** dodaj testerów wewnętrznych (do 100) lub zewnętrznych (review Apple ~24–48 h).
5. **Checklist przed uploadem:**
   - `GoogleService-Info.plist` w projekcie lokalnie
   - App Groups na obu targetach
   - Ikona 1024×1024 w Assets
   - `PrivacyInfo.xcprivacy` (UserDefaults / App Groups)
   - `ITSAppUsesNonExemptEncryption = NO` w Info.plist
   - URL prywatności w **App Store Connect** (zgodny z `APIConfig.privacyURL`)

### Szybki test lokalny

```bash
cd FactCheckr
xcodebuild \
  -project FactCheckr.xcodeproj \
  -scheme FactCheckr \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath ./build \
  build
```

Symulator (Debug):

```bash
xcodebuild \
  -project FactCheckr.xcodeproj \
  -scheme FactCheckr \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath ./build \
  build
```

## API

Backend produkcyjny: `https://europe-central2-factcheckr-e33da.cloudfunctions.net/api`

## Struktura

- `Config/` — API, metadane appki
- `Networking/` — PoW, klient API, detekcja URL
- `Auth/` — Firebase email/hasło
- `Services/` — historia lokalna, profil Firestore
- `Views/` — Analiza, Panel, Konto, auth
- `Shared/` — App Group, deep link, Share Extension
- `Theme/` — design system (kolory web-dashboard)

## Ekrany MVP

| Zakładka | Funkcja |
|----------|---------|
| **Analiza** | wklej URL / share → streaming wynik |
| **Panel** | historia, sync Firestore, szczegóły raportu |
| **Konto** | logowanie, plan, prywatność, wersja |
