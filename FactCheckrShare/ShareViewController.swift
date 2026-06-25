import UIKit

final class ShareViewController: UIViewController {
    private let card = UIView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor(red: 0.91, green: 0.90, blue: 0.94, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if let code = UserDefaults(suiteName: AppGroupConfig.identifier)?.string(forKey: "fc_app_lang_code") {
            Loc.currentCode = code
        }
        view.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
        setupUI()
    }

    private func setupUI() {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(red: 0.086, green: 0.086, blue: 0.122, alpha: 1)
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        view.addSubview(card)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = UIColor(red: 0.64, green: 0.61, blue: 0.99, alpha: 1)
        spinner.startAnimating()

        statusLabel.text = Loc.t(.shareExtPassing)

        card.addSubview(spinner)
        card.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            card.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            statusLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            statusLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28),
            spinner.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16)
        ])

        if let logoImage = UIImage(named: "AppLogo") {
            let logo = UIImageView(image: logoImage)
            logo.contentMode = .scaleAspectFit
            logo.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(logo)
            NSLayoutConstraint.activate([
                logo.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
                logo.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                logo.widthAnchor.constraint(equalToConstant: 64),
                logo.heightAnchor.constraint(equalToConstant: 64),
                spinner.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 18)
            ])
        } else {
            spinner.topAnchor.constraint(equalTo: card.topAnchor, constant: 32).isActive = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await handleShare() }
    }

    private func handleShare() async {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            fail(Loc.t(.shareExtReadFail))
            return
        }

        guard let url = await ShareURLExtractor.extractSharedURL(from: items) else {
            fail(Loc.t(.shareExtNoUrl))
            return
        }

        // Persist first so the main app can always pick it up — even if the
        // background hand-off below fails (e.g. user opens the app manually).
        SharedLinkStore.savePendingURL(url)

        statusLabel.text = Loc.t(.shareExtStarting)

        // Preferred path: analyze in the background so the user can stay in the
        // video they were watching. Requires a recent login (fresh ID token).
        let result = await BackgroundAnalysisService.shared.startAnalysis(urlString: url)

        switch result {
        case .started:
            UserDefaults(suiteName: AppGroupConfig.identifier)?.set(true, forKey: "fc_tip_share_eligible")
            NotificationService.requestAuthorization()
            // The background run will produce the result and a push, so don't
            // re-analyze the same link on next launch.
            SharedLinkStore.clearPendingURL()
            finishBackground(Loc.t(.shareExtBackgroundStarted))
        case .notLoggedIn, .failed:
            // Fall back to opening the app (sign-in required or background failed).
            let opened = openMainApp(ShareDeepLink.openAppURL)
            let delay: TimeInterval = opened ? 0.05 : 1.4
            if !opened {
                statusLabel.text = Loc.t(.shareExtOpenApp)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
        }
    }

    private func finishBackground(_ message: String) {
        spinner.stopAnimating()
        spinner.isHidden = true
        statusLabel.text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    /// Opens the host app via its custom URL scheme. Share extensions cannot rely
    /// on `extensionContext.open(_:)` (it frequently returns false), so we walk the
    /// responder chain to find the shared `UIApplication` and call `open` on it.
    @discardableResult
    private func openMainApp(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        let selector = NSSelectorFromString("openURL:")
        while let current = responder {
            if current.responds(to: selector), current.isKind(of: UIApplication.self) {
                let app = current as! UIApplication
                app.open(url, options: [:], completionHandler: nil)
                return true
            }
            responder = current.next
        }
        // Fallback to the (less reliable) extension context API.
        extensionContext?.open(url, completionHandler: nil)
        return false
    }

    private func fail(_ message: String) {
        spinner.stopAnimating()
        spinner.isHidden = true
        statusLabel.text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
