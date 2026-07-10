import Foundation

final class APIClient {
    static let shared = APIClient()
    private let base = APIConfig.baseURL
    private init() {}

    func solveChallenge() async throws -> PowSolution {
        guard let url = URL(string: "\(base)/api/challenge") else {
            throw APIError(message: Loc.t(.errPowChallenge), status: nil)
        }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError(
                message: Loc.t(.errPowChallenge),
                status: (resp as? HTTPURLResponse)?.statusCode
            )
        }
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
    }

    func analyze(
        path: String,
        url: String,
        lang: String = "pl",
        model: String? = nil,
        idToken: String? = nil,
        pow: PowSolution? = nil,
        onProgress: @escaping (AnalysisStage, String?) -> Void
    ) async throws -> Data {
        let resolvedPow: PowSolution
        if let pow {
            resolvedPow = pow
        } else {
            resolvedPow = try await solveChallenge()
        }

        var body: [String: Any] = [
            "url": url.trimmingCharacters(in: .whitespacesAndNewlines),
            "lang": lang,
            "pow": [
                "challenge": resolvedPow.challenge,
                "signature": resolvedPow.signature,
                "nonce": resolvedPow.nonce
            ]
        ]
        if let model { body["model"] = model }

        guard let requestURL = URL(string: "\(base)\(path)") else {
            throw APIError(message: Loc.t(.errAnalysisFailed), status: nil)
        }
        var req = URLRequest(url: requestURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("text/x-ndjson", forHTTPHeaderField: "Accept")
        if let idToken {
            req.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, resp) = try await URLSession.shared.bytes(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        let ct = (resp as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type") ?? ""

        if ct.contains("text/x-ndjson") {
            var finalData: Data?
            for try await line in bytes.lines {
                try Task.checkCancellation()
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, let d = trimmed.data(using: .utf8) else { continue }
                guard let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                      let type = obj["type"] as? String else { continue }
                switch type {
                case "progress":
                    let stage = (obj["stage"] as? String).flatMap(AnalysisStage.init) ?? .analyzing
                    onProgress(stage, obj["detail"] as? String)
                case "result":
                    if let dataObj = obj["data"] {
                        finalData = try JSONSerialization.data(withJSONObject: dataObj)
                    }
                case "error":
                    throw APIError(
                        message: (obj["error"] as? String) ?? Loc.t(.errAnalysisFailed),
                        status: status
                    )
                default:
                    break
                }
            }
            guard let finalData else {
                throw APIError(message: Loc.t(.errEmptyAnalysis), status: status)
            }
            return finalData
        }

        var collected = Data()
        for try await b in bytes {
            try Task.checkCancellation()
            collected.append(b)
        }
        if status >= 400 {
            let msg = (try? JSONSerialization.jsonObject(with: collected) as? [String: Any])?["error"] as? String
            throw APIError(message: msg ?? "\(Loc.t(.errAnalysisFailed)) (\(status))", status: status)
        }
        return collected
    }

    func sendVerificationEmail(idToken: String, lang: String = "pl") async throws {
        guard let url = URL(string: "\(base)/api/auth/send-verification-email") else {
            throw APIError(message: Loc.t(.errSendVerification), status: nil)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["lang": lang])

        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw APIError(message: msg ?? Loc.t(.errSendVerification), status: status)
        }
    }
}
