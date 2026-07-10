import Foundation
import FirebaseFirestore

@MainActor
final class UserProfileService {
    static let shared = UserProfileService()

    private var isConfigured: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    private func mapProfile(uid: String, data: [String: Any]) -> UserProfile {
        UserProfile(
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
    }

    /// Mirrors the web dashboard's `ensureUserProfile`: reads the user document and,
    /// if it does not exist yet, creates it client-side with the default free quota.
    /// Firestore rules allow this exact shape (freeTokens == 5, totalAnalyses == 0, plan == "free").
    @discardableResult
    func ensureUserProfile(uid: String, email: String?, displayName: String?, photoURL: String?) async -> UserProfile {
        let fallback = UserProfile(
            uid: uid,
            email: email,
            displayName: displayName,
            freeTokens: 5,
            totalAnalyses: 0,
            plan: "free",
            testerStatus: "none",
            monthlyAnalysisLimit: nil,
            monthlyAnalysisMonth: nil,
            monthlyAnalysesUsed: nil
        )
        guard isConfigured else { return fallback }

        let ref = Firestore.firestore().collection("users").document(uid)
        do {
            let snap = try await ref.getDocument()
            if snap.exists, var data = snap.data() {
                // Backfill the display name once we have it (Apple only sends the
                // full name on the very first sign-in).
                let existingName = (data["displayName"] as? String) ?? ""
                if existingName.isEmpty, let displayName, !displayName.isEmpty {
                    try? await ref.updateData([
                        "displayName": displayName,
                        "updatedAt": FieldValue.serverTimestamp()
                    ])
                    data["displayName"] = displayName
                }
                return mapProfile(uid: uid, data: data)
            }

            var newDoc: [String: Any] = [
                "uid": uid,
                "freeTokens": 5,
                "totalAnalyses": 0,
                "plan": "free",
                "testerStatus": "none",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            if let email { newDoc["email"] = email }
            if let displayName, !displayName.isEmpty { newDoc["displayName"] = displayName }
            if let photoURL, !photoURL.isEmpty { newDoc["photoURL"] = photoURL }

            try await ref.setData(newDoc)
            PostLoginTutorialStore.schedule(for: uid)
            return fallback
        } catch {
            return fallback
        }
    }

    func fetchProfile(uid: String) async -> UserProfile? {
        guard isConfigured else { return nil }
        do {
            let snap = try await Firestore.firestore().collection("users").document(uid).getDocument()
            guard snap.exists, let data = snap.data() else { return nil }
            return mapProfile(uid: uid, data: data)
        } catch {
            return nil
        }
    }

    /// Deletes the Firestore user profile and analysis history. Requires security rules that allow the owner to delete their data.
    func deleteAllUserData(uid: String) async throws {
        guard isConfigured else { return }
        let db = Firestore.firestore()
        let analysesRef = db.collection("users").document(uid).collection("analyses")

        while true {
            let snap = try await analysesRef.limit(to: 100).getDocuments()
            if snap.documents.isEmpty { break }
            let batch = db.batch()
            for doc in snap.documents {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commit()
        }

        try await db.collection("users").document(uid).delete()
    }

    /// Best-effort remote delete. Tries document ID first, then matches by sourceUrl
    /// because local UUIDs often differ from Firestore document IDs.
    func deleteAnalysis(uid: String, entryId: String, sourceUrl: String? = nil) async throws {
        guard isConfigured else { return }
        let analyses = Firestore.firestore()
            .collection("users").document(uid)
            .collection("analyses")

        do {
            try await analyses.document(entryId).delete()
        } catch {
            // Fall through to URL-based delete.
        }

        guard let sourceUrl, !sourceUrl.isEmpty else { return }

        let snap = try await analyses.whereField("sourceUrl", isEqualTo: sourceUrl).getDocuments()
        guard !snap.documents.isEmpty else { return }

        let batch = Firestore.firestore().batch()
        for doc in snap.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
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

        let analysis = decodeAnalysisResult(from: report) ?? AnalysisResult(
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
            scoreReasoning: report["scoreReasoning"] as? String,
            evidenceSummary: nil
        )

        let response = AnalysisResponse(
            success: true,
            url: sourceUrl,
            pageTitle: data["title"] as? String,
            transcript: report["transcript"] as? String,
            transcriptLanguage: report["transcriptLanguage"] as? String,
            audioDuration: report["audioDuration"] as? Double,
            analysisTimeMs: report["analysisTimeMs"] as? Int,
            cached: report["cached"] as? Bool,
            modelUsed: report["modelUsed"] as? String,
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

    private func decodeAnalysisResult(from report: [String: Any]) -> AnalysisResult? {
        guard JSONSerialization.isValidJSONObject(report),
              let data = try? JSONSerialization.data(withJSONObject: report) else { return nil }
        return try? JSONDecoder().decode(AnalysisResult.self, from: data)
    }
}
