import Foundation
import FirebaseFirestore

@MainActor
final class UserProfileService {
    static let shared = UserProfileService()

    func fetchProfile(uid: String) async -> UserProfile? {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return nil
        }
        do {
            let snap = try await Firestore.firestore().collection("users").document(uid).getDocument()
            guard snap.exists, let data = snap.data() else { return nil }
            return UserProfile(
                uid: uid,
                email: data["email"] as? String,
                displayName: data["displayName"] as? String,
                freeTokens: data["freeTokens"] as? Int ?? 5,
                totalAnalyses: data["totalAnalyses"] as? Int ?? 0,
                plan: data["plan"] as? String ?? "free",
                testerStatus: data["testerStatus"] as? String,
                monthlyAnalysisLimit: data["monthlyAnalysisLimit"] as? Int,
                monthlyAnalysisMonth: data["monthlyAnalysisMonth"] as? String,
                monthlyAnalysesUsed: data["monthlyAnalysesUsed"] as? Int
            )
        } catch {
            return nil
        }
    }

    func fetchRemoteHistory(uid: String, limit: Int = 50) async -> [AnalysisHistoryEntry] {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return []
        }
        do {
            let snap = try await Firestore.firestore()
                .collection("users").document(uid)
                .collection("analyses")
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
                .getDocuments()

            return snap.documents.compactMap { doc in
                mapFirestoreEntry(id: doc.documentID, data: doc.data())
            }
        } catch {
            return []
        }
    }

    private func mapFirestoreEntry(id: String, data: [String: Any]) -> AnalysisHistoryEntry? {
        guard let sourceUrl = data["sourceUrl"] as? String else { return nil }
        let report = data["report"] as? [String: Any] ?? [:]
        let score = (data["overallScore"] as? Int) ?? (report["credibilityScore"] as? Int) ?? 0
        let threatRaw = data["threatLevel"] as? String ?? ThreatLevel.from(score: score).rawValue
        let threat = ThreatLevel(rawValue: threatRaw) ?? .medium

        let analysis = AnalysisResult(
            credibilityScore: report["credibilityScore"] as? Int,
            manipulationScore: report["manipulationScore"] as? Int,
            confidenceScore: report["confidenceScore"] as? Int,
            verdict: report["verdict"] as? String,
            summary: report["summary"] as? String,
            overallAssessment: report["overallAssessment"] as? String,
            claims: nil,
            indicators: nil,
            manipulationSignals: nil,
            sourceAssessment: nil,
            missingContext: report["missingContext"] as? [String],
            correctedInfo: report["correctedInfo"] as? String,
            categories: report["categories"] as? [String],
            detectedLanguage: report["detectedLanguage"] as? String,
            contentType: nil,
            scoreReasoning: nil,
            evidenceSummary: nil
        )

        let response = AnalysisResponse(
            success: true,
            url: sourceUrl,
            transcript: nil,
            transcriptLanguage: nil,
            audioDuration: nil,
            analysisTimeMs: nil,
            cached: nil,
            modelUsed: nil,
            analysis: analysis
        )

        let ts = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let type = data["type"] as? String ?? "Artykuł"
        let title = data["title"] as? String ?? report["summary"] as? String ?? sourceUrl

        return AnalysisHistoryEntry(
            id: id,
            sourceUrl: sourceUrl,
            title: String(title.prefix(120)),
            type: type,
            threatLevel: threat,
            overallScore: score,
            verdict: report["verdict"] as? String,
            createdAt: ts,
            response: response
        )
    }
}
