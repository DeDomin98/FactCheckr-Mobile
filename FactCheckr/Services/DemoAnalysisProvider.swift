import Foundation

/// Bundled sample analysis for the post-login tutorial. Never hits the API — zero token cost.
enum DemoAnalysisProvider {
    static let demoURL =
        "https://www.rp.pl/polityka/art44737061-sad-najwyzszy-zniweczyl-plan-trumpa-prezydent-usa-mozemy-to-latwo-naprawic-w-kongresie"

    static let demoArticleTitle =
        "Sąd Najwyższy zniweczył plan Trumpa. Prezydent USA: Możemy to łatwo naprawić w Kongresie"

    static func makeResponse() -> AnalysisResponse {
        AnalysisResponse(
            success: true,
            url: demoURL,
            pageTitle: demoArticleTitle,
            transcript: nil,
            transcriptLanguage: nil,
            audioDuration: nil,
            analysisTimeMs: 4200,
            cached: true,
            modelUsed: "demo",
            analysis: AnalysisResult(
                credibilityScore: 84,
                manipulationScore: 12,
                confidenceScore: 88,
                verdict: "well_supported",
                summary: "Artykuł rp.pl poprawnie relacjonuje decyzję Sądu Najwyższego USA w sprawie dekretu Donalda Trumpa o ograniczeniu obywatelstwa z urodzenia. Kluczowe twierdzenia odpowiadają ustaleniom mediów amerykańskich i treści 14. poprawki do Konstytucji USA.",
                overallAssessment: "Tekst jest reportażem newsowym opartym na faktach sądowych i publicznych wypowiedziach Trumpa. Autor nie przypisuje dekretowi mocy prawnej po wyroku i wyjaśnia kontekst konstytucyjny (ius soli). Ton jest informacyjny, bez wyraźnej propagandy.",
                justification: nil,
                claims: [
                    Claim(
                        claim: "Sąd Najwyższy Stanów Zjednoczonych unieważnił dekret Donalda Trumpa ograniczający prawo do obywatelstwa z urodzenia.",
                        type: "factual",
                        verifiability: "high",
                        supportLevel: "strong",
                        status: "confirmed",
                        reason: "Potwierdzone przez doniesienia amerykańskich mediów i oficjalne komunikaty sądowe.",
                        verdict: "true",
                        researchSummary: "Wyrok SN USA uznał rozporządzenie wykonawcze za niezgodne z 14. poprawką do Konstytucji.",
                        keyFindings: [
                            "Dekret podpisany 20 stycznia 2025 r. został zaskarżony przez organizacje praw człowieka.",
                            "Sędziowie wskazali, że obywatelstwo z urodzenia wynika wprost z konstytucji."
                        ],
                        sourceBreakdown: SourceBreakdown(confirming: 6, contradicting: 0, neutral: 1),
                        groundingSources: [
                            GroundingSource(title: "Reuters — Supreme Court ruling", url: "https://www.reuters.com"),
                            GroundingSource(title: "SCOTUSblog — Birthright citizenship", url: "https://www.scotusblog.com")
                        ]
                    ),
                    Claim(
                        claim: "Sześciu z dziewięciu sędziów uznało dekret za nielegalny; Brett Kavanaugh zajął odrębne stanowisko co do podstawy prawnej.",
                        type: "factual",
                        verifiability: "high",
                        supportLevel: "strong",
                        status: "confirmed",
                        reason: "Skład orzekający i podział głosów są udokumentowane w relacjach prasowych.",
                        verdict: "true",
                        researchSummary: "Większość sędziów odrzuciła argumentację administracji; jeden sędzia kwestionował interpretację ustawy, nie samą zasadę obywatelstwa z urodzenia.",
                        keyFindings: [
                            "John Roberts napisał opinię dla większości.",
                            "Media podkreślają historyczny charakter prawa ziemi w USA."
                        ],
                        sourceBreakdown: SourceBreakdown(confirming: 5, contradicting: 0, neutral: 2),
                        groundingSources: [
                            GroundingSource(title: "Associated Press — Court blocks order", url: "https://apnews.com")
                        ]
                    ),
                    Claim(
                        claim: "Donald Trump zapowiedział, że te same restrykcje wprowadzi ustawą Kongresu zamiast dekretu.",
                        type: "quote",
                        verifiability: "high",
                        supportLevel: "strong",
                        status: "confirmed",
                        reason: "Wypowiedź opublikowana na Truth Social jest cytowana w artykule i potwierdzona przez inne media.",
                        verdict: "true",
                        researchSummary: "Prezydent skomentował wyrok jako niekorzystny, ale wskazał na ścieżkę legislacyjną.",
                        keyFindings: [
                            "Trump nie zapowiedział natychmiastowego ponownego wydania identycznego dekretu.",
                            "Przejście przez Kongres wymagałoby szerszego poparcia politycznego."
                        ],
                        sourceBreakdown: SourceBreakdown(confirming: 4, contradicting: 0, neutral: 1),
                        groundingSources: [
                            GroundingSource(title: "Truth Social — post Donalda Trumpa", url: "https://truthsocial.com")
                        ]
                    )
                ],
                indicators: [
                    Indicator(label: "Źródła pierwotne", status: "positive", detail: "Odwołanie do wyroku sądu i cytat z 14. poprawki."),
                    Indicator(label: "Kontekst historyczny", status: "positive", detail: "Wyjaśnienie zasady ius soli i daty podpisania dekretu."),
                    Indicator(label: "Balans polityczny", status: "neutral", detail: "Relacja faktów sądowych z reakcją prezydenta bez oceny wartościującej.")
                ],
                manipulationSignals: [],
                manipulationTechniques: nil,
                sourceAssessment: SourceAssessment(
                    transparency: "high",
                    strengths: "Gazeta opisuje ustalenia sądu, cytuje konstytucję i reakcję polityka.",
                    weaknesses: "Skrócona relacja nie omawia wszystkich argumentów prawnych stron."
                ),
                missingContext: [
                    "Artykuł nie analizuje realnej szansy przejścia ustawy przez Kongres.",
                    "Brak szczegółowego omówienia wpływu wyroku na konkretne rodziny imigrantów."
                ],
                correctedInfo: nil,
                categories: ["Polityka", "USA", "Prawo konstytucyjne"],
                detectedLanguage: "pl",
                contentType: "news_article",
                modelUsed: "demo",
                scoreReasoning: "Wysoka ocena wynika z zgodności z wiarygodnymi doniesieniami o wyroku SN, poprawnego opisu 14. poprawki i braku istotnych fałszywych twierdzeń. Lekkie obniżenie za brak głębszej analizy politycznej.",
                evidenceSummary: EvidenceSummary(totalClaims: 3, totalSources: 9, confirming: 15, contradicting: 0, neutral: 4),
                pipelineMetadata: PipelineMetadata(
                    totalAgentCalls: 3,
                    groundedSearch: true,
                    flowVersion: "demo",
                    sourcesUsed: ["reuters.com", "apnews.com", "scotusblog.com"]
                ),
                mbfcResult: MbfcResult(
                    domain: "rp.pl",
                    biasLabel: "Right-Center",
                    factualLabel: "Mostly Factual",
                    credibilityLabel: "High",
                    isQuestionable: false
                ),
                allGroundingSources: [
                    GroundingSource(title: "Reuters", url: "https://www.reuters.com"),
                    GroundingSource(title: "Associated Press", url: "https://apnews.com"),
                    GroundingSource(title: "SCOTUSblog", url: "https://www.scotusblog.com"),
                    GroundingSource(title: "Rzeczpospolita — artykuł źródłowy", url: demoURL)
                ]
            )
        )
    }

    static func makeHistoryEntry() -> AnalysisHistoryEntry {
        AnalysisHistoryEntry(
            sourceUrl: demoURL,
            endpoint: .article,
            response: makeResponse()
        )
    }
}
