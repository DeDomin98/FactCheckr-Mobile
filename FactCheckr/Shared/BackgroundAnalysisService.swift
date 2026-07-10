import Foundation

/// Runs link analysis through a background `URLSession` so the share extension can
/// kick off a check and let the user keep watching their video. When the transfer
/// finishes the system delivers the result either to the still-alive extension or
/// to the relaunched host app; either way we store the result for the right account
/// and fire a local notification.
final class BackgroundAnalysisService: NSObject {
    static let shared = BackgroundAnalysisService()

    static let sessionIdentifier = "com.factcheckr.bg-analysis"

    /// Set by the app delegate when the system relaunches the app for session events.
    var backgroundCompletionHandler: (() -> Void)?

    private var buffers: [Int: Data] = [:]
    private let lock = NSLock()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
        config.sharedContainerIdentifier = AppGroupConfig.identifier
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 10 * 60
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    /// Ensures the background session (and its delegate) exists in this process so
    /// pending completion events can be delivered. Call early in app launch.
    func activate() {
        _ = session
        NotificationService.refreshAuthorization()
    }

    // MARK: - Starting an analysis (called from the share extension)

    enum StartResult {
        case started
        case notLoggedIn
        case failed
    }

    func startAnalysis(urlString: String) async -> StartResult {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failed }
        guard let auth = AppGroupTokenStore.validToken() else { return .notLoggedIn }

        // Already finished in background while the extension was open.
        if BackgroundAnalysisStore.peek(sourceUrl: trimmed, uid: auth.uid) != nil {
            SharedLinkStore.clearPendingURL()
            return .started
        }

        // Avoid duplicate background uploads for the same URL.
        if BackgroundInflightStore.isInflight(url: trimmed, uid: auth.uid) {
            return .started
        }

        let endpoint = pickEndpoint(trimmed)

        guard let pow = await solveChallenge() else { return .failed }

        let lang = UserDefaults(suiteName: AppGroupConfig.identifier)?.string(forKey: "fc_app_lang_code") ?? "pl"
        var body: [String: Any] = [
            "url": trimmed,
            "lang": lang,
            "pow": [
                "challenge": pow.challenge,
                "signature": pow.signature,
                "nonce": pow.nonce
            ]
        ]
        if endpoint == .article { body["model"] = APIConfig.articleModel }

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body),
              let fileURL = writeBodyFile(bodyData),
              let requestURL = URL(string: "\(APIConfig.baseURL)\(endpoint.path)") else { return .failed }

        var req = URLRequest(url: requestURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("text/x-ndjson", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(auth.token)", forHTTPHeaderField: "Authorization")

        let task = session.uploadTask(with: req, fromFile: fileURL)
        let meta = encodeMeta(url: trimmed, endpoint: endpoint, uid: auth.uid, bodyPath: fileURL.path)
        guard !meta.isEmpty else { return .failed }
        task.taskDescription = meta
        BackgroundInflightStore.markStarted(url: trimmed, uid: auth.uid)
        task.resume()
        return .started
    }

    // MARK: - Challenge / PoW

    private func solveChallenge() async -> PowSolution? {
        guard let url = URL(string: "\(APIConfig.baseURL)/api/challenge") else { return nil }
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            struct ChallengeResp: Decodable {
                let challenge: String
                let signature: String
                let difficulty: Int
            }
            let c = try JSONDecoder().decode(ChallengeResp.self, from: data)
            let nonce = await Task.detached(priority: .userInitiated) {
                solvePoW(challenge: c.challenge, difficulty: c.difficulty)
            }.value
            return PowSolution(challenge: c.challenge, signature: c.signature, nonce: nonce)
        } catch {
            return nil
        }
    }

    // MARK: - Body file + meta

    private func writeBodyFile(_ data: Data) -> URL? {
        let dir = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroupConfig.identifier)?
            .appendingPathComponent("bg-bodies", isDirectory: true)
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(UUID().uuidString).json")
        do {
            try data.write(to: file)
            return file
        } catch {
            return nil
        }
    }

    private struct TaskMeta: Codable {
        let url: String
        let endpoint: String
        let uid: String
        let bodyPath: String
    }

    private func encodeMeta(url: String, endpoint: AnalyzeEndpoint, uid: String, bodyPath: String) -> String {
        let meta = TaskMeta(url: url, endpoint: endpoint.metaValue, uid: uid, bodyPath: bodyPath)
        guard let data = try? JSONEncoder().encode(meta), let str = String(data: data, encoding: .utf8) else {
            return ""
        }
        return str
    }

    private func decodeMeta(_ description: String?) -> TaskMeta? {
        guard let description, !description.isEmpty, let data = description.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(TaskMeta.self, from: data)
    }

    // MARK: - Result handling

    private func handleCompletion(meta: TaskMeta, body: Data, statusCode: Int) {
        if !meta.bodyPath.isEmpty {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: meta.bodyPath))
        }

        BackgroundInflightStore.clear(url: meta.url, uid: meta.uid)

        guard statusCode < 400, let resultData = extractResultData(from: body) else {
            handleFailure(meta: meta, statusCode: statusCode)
            return
        }

        guard let response = try? JSONDecoder().decode(AnalysisResponse.self, from: resultData) else {
            handleFailure(meta: meta, statusCode: statusCode)
            return
        }

        let endpoint = AnalyzeEndpoint(metaValue: meta.endpoint)
        let entry = AnalysisHistoryEntry(sourceUrl: meta.url, endpoint: endpoint, response: response)
        BackgroundAnalysisStore.add(entry: entry, uid: meta.uid)
        // Keep deep-link payload ready even before the user taps the notification
        // (covers the case when the app is already open / relaunched).
        NotificationDeepLinkStore.saveReady(entryId: entry.id, uid: meta.uid, sourceUrl: meta.url)
        SharedLinkStore.clearPendingURL()
        UserDefaults(suiteName: AppGroupConfig.identifier)?.set(true, forKey: "fc_tip_share_eligible")

        notify(entry: entry, uid: meta.uid)
    }

    private func handleFailure(meta: TaskMeta, statusCode: Int) {
        BackgroundInflightStore.clear(url: meta.url, uid: meta.uid)

        // Race: foreground retry or duplicate task may have succeeded already.
        if BackgroundAnalysisStore.peek(sourceUrl: meta.url, uid: meta.uid) != nil {
            SharedLinkStore.clearPendingURL()
            return
        }

        SharedLinkStore.savePendingURL(meta.url)
        let message: String
        switch statusCode {
        case 401, 402:
            message = Loc.t(.notifBackgroundAuthFail)
        case 403:
            message = Loc.t(.errVerifyEmail)
        case 422:
            message = Loc.t(.errVideoTooLong)
        case 504, 599:
            message = Loc.t(.errTimeout)
        default:
            message = Loc.t(.notifBackgroundFail)
        }
        NotificationService.postAnalysisFailed(url: meta.url, message: message)
    }

    /// Parses the NDJSON stream and returns the serialized `data` payload of the
    /// final `result` line.
    private func extractResultData(from body: Data) -> Data? {
        guard let text = String(data: body, encoding: .utf8) else { return nil }
        var result: Data?
        for rawLine in text.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, let d = line.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                  let type = obj["type"] as? String else { continue }
            if type == "error" { return nil }
            if type == "result", let dataObj = obj["data"] {
                result = try? JSONSerialization.data(withJSONObject: dataObj)
            }
        }
        return result
    }

    private func notify(entry: AnalysisHistoryEntry, uid: String) {
        NotificationService.postAnalysisReady(entry: entry, uid: uid)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .fcOpenAnalysisResult, object: nil)
        }
    }
}

extension BackgroundAnalysisService: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        buffers[dataTask.taskIdentifier, default: Data()].append(data)
        lock.unlock()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        let body = buffers[task.taskIdentifier] ?? Data()
        buffers[task.taskIdentifier] = nil
        lock.unlock()

        guard let meta = decodeMeta(task.taskDescription) else {
            #if DEBUG
            print("[BackgroundAnalysis] missing task meta — completion dropped")
            #endif
            // Best-effort: clear any stale inflight markers so Home doesn't hang forever.
            BackgroundInflightStore.removeExpired()
            return
        }

        let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? 0

        // Prefer parsed body when present — some background transfers report an error
        // even though the response payload arrived.
        if !body.isEmpty {
            handleCompletion(meta: meta, body: body, statusCode: statusCode == 0 ? 200 : statusCode)
            return
        }

        if error != nil {
            handleFailure(meta: meta, statusCode: statusCode == 0 ? 599 : statusCode)
            return
        }

        handleCompletion(meta: meta, body: body, statusCode: statusCode == 0 ? 200 : statusCode)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { [weak self] in
            let handler = self?.backgroundCompletionHandler
            self?.backgroundCompletionHandler = nil
            handler?()
        }
    }
}
