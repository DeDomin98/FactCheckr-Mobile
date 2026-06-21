import UIKit

final class ShareViewController: UIViewController {
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
        view.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
        statusLabel.text = "Otwieram Fact Checkr…"
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await handleShare() }
    }

    private func handleShare() async {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            fail("Nie udało się odczytać udostępnionej treści.")
            return
        }

        guard let url = await ShareURLExtractor.extractSharedURL(from: items) else {
            fail("Nie znaleziono linku. Udostępnij post z adresem URL.")
            return
        }

        SharedLinkStore.savePendingURL(url)

        guard let context = extensionContext else {
            fail("Błąd rozszerzenia.")
            return
        }

        statusLabel.text = "Uruchamiam analizę…"
        context.open(ShareDeepLink.openAppURL) { _ in
            context.completeRequest(returningItems: nil)
        }
    }

    private func fail(_ message: String) {
        statusLabel.text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
