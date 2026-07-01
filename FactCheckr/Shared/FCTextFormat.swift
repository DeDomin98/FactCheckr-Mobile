import Foundation

enum FCTextFormat {
    /// Replaces em/en dashes and similar long dashes with a simple hyphen for display.
    static func display(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\u{2014}", with: "-")
            .replacingOccurrences(of: "\u{2013}", with: "-")
            .replacingOccurrences(of: "\u{2015}", with: "-")
            .replacingOccurrences(of: "\u{2212}", with: "-")
    }

    static func manipulationLabel(_ raw: String) -> String {
        let key = normalizeKey(raw)
        if Loc.code == "pl", let label = polishManipulationLabels[key] {
            return label
        }
        if let label = englishManipulationLabels[key] {
            return label
        }
        return humanizeKey(raw)
    }

    static func manipulationIcon(_ raw: String) -> String {
        switch normalizeKey(raw) {
        case "us_vs_them", "us_versus_them": return "person.2.fill"
        case "emotional_language", "loaded_language", "emotionally_charged_language": return "heart.text.square.fill"
        case "cherry_picking", "selective_evidence": return "leaf.fill"
        case "false_dichotomy", "false_choice", "either_or_fallacy": return "arrow.left.arrow.right"
        case "appeal_to_authority", "authority_bias": return "person.badge.shield.checkmark.fill"
        case "straw_man", "strawman": return "figure.stand.line.dotted.figure.stand"
        case "fear_mongering", "fear_appeal": return "bolt.trianglebadge.exclamationmark.fill"
        case "bandwagon", "appeal_to_popularity": return "person.3.fill"
        case "whataboutism", "whatabout": return "arrow.turn.up.right"
        case "ad_hominem", "personal_attack": return "person.crop.circle.badge.exclamationmark"
        case "misleading_statistics", "misleading_statistic": return "chart.bar.xaxis"
        case "out_of_context", "missing_context", "context_omission": return "scissors"
        case "conspiracy_framing", "conspiracy": return "eye.trianglebadge.exclamationmark.fill"
        case "sensationalism": return "megaphone.fill"
        case "oversimplification": return "minus.circle.fill"
        case "false_equivalence": return "equal.circle.fill"
        case "gaslighting": return "cloud.fog.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private static func normalizeKey(_ raw: String) -> String {
        raw.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }

    private static func humanizeKey(_ raw: String) -> String {
        normalizeKey(raw)
            .split(separator: "_")
            .map { part in
                let s = String(part)
                return s.prefix(1).uppercased() + s.dropFirst()
            }
            .joined(separator: " ")
    }

    private static let polishManipulationLabels: [String: String] = [
        "us_vs_them": "My kontra oni",
        "us_versus_them": "My kontra oni",
        "emotional_language": "Język emocjonalny",
        "loaded_language": "Język nacechowany",
        "cherry_picking": "Wybiórcze dowody",
        "selective_evidence": "Wybiórcze dowody",
        "false_dichotomy": "Fałszywy dylemat",
        "false_choice": "Fałszywy wybór",
        "appeal_to_authority": "Apel do autorytetu",
        "straw_man": "Sojka",
        "strawman": "Sojka",
        "fear_mongering": "Straszenie",
        "fear_appeal": "Apel do strachu",
        "bandwagon": "Efekt tłumu",
        "appeal_to_popularity": "Apel do popularności",
        "whataboutism": "Whataboutism",
        "whatabout": "A u was…",
        "ad_hominem": "Atak ad hominem",
        "personal_attack": "Atak personalny",
        "misleading_statistics": "Mylące statystyki",
        "out_of_context": "Wyrwanie z kontekstu",
        "missing_context": "Brak kontekstu",
        "conspiracy_framing": "Narracja spiskowa",
        "sensationalism": "Sensacyjność",
        "oversimplification": "Nadmierne uproszczenie",
        "false_equivalence": "Fałszywa równoważność",
        "gaslighting": "Gaslighting"
    ]

    private static let englishManipulationLabels: [String: String] = [
        "us_vs_them": "Us vs. them",
        "us_versus_them": "Us vs. them",
        "emotional_language": "Emotional language",
        "loaded_language": "Loaded language",
        "cherry_picking": "Cherry-picking",
        "selective_evidence": "Selective evidence",
        "false_dichotomy": "False dichotomy",
        "false_choice": "False choice",
        "appeal_to_authority": "Appeal to authority",
        "straw_man": "Straw man",
        "strawman": "Straw man",
        "fear_mongering": "Fear-mongering",
        "fear_appeal": "Fear appeal",
        "bandwagon": "Bandwagon effect",
        "appeal_to_popularity": "Appeal to popularity",
        "whataboutism": "Whataboutism",
        "whatabout": "Whataboutism",
        "ad_hominem": "Ad hominem",
        "personal_attack": "Personal attack",
        "misleading_statistics": "Misleading statistics",
        "out_of_context": "Out of context",
        "missing_context": "Missing context",
        "conspiracy_framing": "Conspiracy framing",
        "sensationalism": "Sensationalism",
        "oversimplification": "Oversimplification",
        "false_equivalence": "False equivalence",
        "gaslighting": "Gaslighting"
    ]
}

extension String {
    var fcDisplay: String { FCTextFormat.display(self) }
    var fcManipulationLabel: String { FCTextFormat.manipulationLabel(self) }
}
