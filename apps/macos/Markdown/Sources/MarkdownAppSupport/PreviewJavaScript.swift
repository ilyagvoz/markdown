import Foundation

public enum PreviewJavaScript {
    public static func stringLiteral(_ value: String) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let encoded = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }
        return encoded
    }

    public static func jumpToAnchorScript(anchorID: String) -> String {
        "window.markdownJumpTo(\(stringLiteral(anchorID)));"
    }

    public static func findTextScript(query: String, occurrence: Int) -> String {
        "window.markdownFindText(\(stringLiteral(query)), \(occurrence));"
    }
}
