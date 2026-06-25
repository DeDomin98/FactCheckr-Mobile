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
}

extension String {
    var fcDisplay: String { FCTextFormat.display(self) }
}
