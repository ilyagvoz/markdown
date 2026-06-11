import Foundation

public enum MarkdownLinePresentation: Equatable, Sendable {
    case blank
    case paragraph
    case heading(level: Int)
    case unorderedList(marker: String)
    case orderedList(marker: String)
    case quote
    case fencedCode(marker: String)
    case codeContent
}

public struct MarkdownEditableLine: Equatable, Sendable {
    public let source: String
    public let presentation: MarkdownLinePresentation
    public let visibleText: String
    public let markerPrefix: String
    public let markerSuffix: String

    public var unlockedSource: String {
        source
    }

    public func source(replacingVisibleText newText: String) -> String {
        markerPrefix + newText + markerSuffix
    }
}

public struct MarkdownLineDocument: Equatable, Sendable {
    public private(set) var lines: [MarkdownEditableLine]

    public init(markdown: String) {
        lines = Self.parse(markdown: markdown)
    }

    public func serialized() -> String {
        lines.map(\.source).joined(separator: "\n")
    }

    public mutating func replaceVisibleText(at index: Int, with newText: String) {
        guard lines.indices.contains(index) else { return }
        let line = lines[index]
        lines[index] = Self.parseLine(line.source(replacingVisibleText: newText), isInsideCodeFence: line.presentation == .codeContent)
    }

    private static func parse(markdown: String) -> [MarkdownEditableLine] {
        var parsed: [MarkdownEditableLine] = []
        var isInsideCodeFence = false

        for sourceLine in markdown.components(separatedBy: "\n") {
            let line = parseLine(sourceLine, isInsideCodeFence: isInsideCodeFence)
            parsed.append(line)
            if case .fencedCode = line.presentation {
                isInsideCodeFence.toggle()
            }
        }

        return parsed
    }

    private static func parseLine(_ source: String, isInsideCodeFence: Bool) -> MarkdownEditableLine {
        if source.isEmpty {
            return MarkdownEditableLine(source: source, presentation: .blank, visibleText: "", markerPrefix: "", markerSuffix: "")
        }

        if isInsideCodeFence, !isFence(source) {
            return MarkdownEditableLine(source: source, presentation: .codeContent, visibleText: source, markerPrefix: "", markerSuffix: "")
        }

        if let fence = parseFence(source) {
            return fence
        }

        if let heading = parseHeading(source) {
            return heading
        }

        if let unordered = parseUnorderedList(source) {
            return unordered
        }

        if let ordered = parseOrderedList(source) {
            return ordered
        }

        if let quote = parseQuote(source) {
            return quote
        }

        return MarkdownEditableLine(source: source, presentation: .paragraph, visibleText: source, markerPrefix: "", markerSuffix: "")
    }

    private static func parseFence(_ source: String) -> MarkdownEditableLine? {
        let leading = leadingWhitespace(in: source)
        let rest = String(source.dropFirst(leading.count))
        guard rest.hasPrefix("```") || rest.hasPrefix("~~~") else { return nil }
        let marker = String(rest.prefix(3))
        let language = String(rest.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        return MarkdownEditableLine(
            source: source,
            presentation: .fencedCode(marker: marker),
            visibleText: language,
            markerPrefix: leading + marker,
            markerSuffix: ""
        )
    }

    private static func parseHeading(_ source: String) -> MarkdownEditableLine? {
        let leading = leadingWhitespace(in: source)
        guard leading.count <= 3 else { return nil }
        let rest = String(source.dropFirst(leading.count))
        let marker = String(rest.prefix { $0 == "#" })
        guard (1...6).contains(marker.count) else { return nil }
        let afterMarker = String(rest.dropFirst(marker.count))
        guard afterMarker.first?.isWhitespace == true else { return nil }
        let body = afterMarker.trimmingCharacters(in: .whitespaces)
        let cleanedBody = body.replacingOccurrences(of: #"\s+#+\s*$"#, with: "", options: .regularExpression)
        let suffix = String(body.dropFirst(cleanedBody.count))
        return MarkdownEditableLine(
            source: source,
            presentation: .heading(level: marker.count),
            visibleText: cleanedBody,
            markerPrefix: leading + marker + " ",
            markerSuffix: suffix
        )
    }

    private static func parseUnorderedList(_ source: String) -> MarkdownEditableLine? {
        let leading = leadingWhitespace(in: source)
        let rest = String(source.dropFirst(leading.count))
        guard let first = rest.first, "-+*".contains(first) else { return nil }
        let afterMarker = String(rest.dropFirst())
        guard afterMarker.first?.isWhitespace == true else { return nil }
        return MarkdownEditableLine(
            source: source,
            presentation: .unorderedList(marker: String(first)),
            visibleText: afterMarker.trimmingCharacters(in: .whitespaces),
            markerPrefix: leading + String(first) + " ",
            markerSuffix: ""
        )
    }

    private static func parseOrderedList(_ source: String) -> MarkdownEditableLine? {
        let leading = leadingWhitespace(in: source)
        let rest = String(source.dropFirst(leading.count))
        let digits = String(rest.prefix { $0.isNumber })
        guard !digits.isEmpty else { return nil }
        let afterDigits = String(rest.dropFirst(digits.count))
        guard let delimiter = afterDigits.first, delimiter == "." || delimiter == ")" else { return nil }
        let afterMarker = String(afterDigits.dropFirst())
        guard afterMarker.first?.isWhitespace == true else { return nil }
        let marker = digits + String(delimiter)
        return MarkdownEditableLine(
            source: source,
            presentation: .orderedList(marker: marker),
            visibleText: afterMarker.trimmingCharacters(in: .whitespaces),
            markerPrefix: leading + marker + " ",
            markerSuffix: ""
        )
    }

    private static func parseQuote(_ source: String) -> MarkdownEditableLine? {
        let leading = leadingWhitespace(in: source)
        let rest = String(source.dropFirst(leading.count))
        guard rest.hasPrefix(">") else { return nil }
        let afterMarker = String(rest.dropFirst())
        let hasSpace = afterMarker.first?.isWhitespace == true
        return MarkdownEditableLine(
            source: source,
            presentation: .quote,
            visibleText: hasSpace ? afterMarker.trimmingCharacters(in: .whitespaces) : afterMarker,
            markerPrefix: leading + ">" + (hasSpace ? " " : ""),
            markerSuffix: ""
        )
    }

    private static func isFence(_ source: String) -> Bool {
        parseFence(source) != nil
    }

    private static func leadingWhitespace(in source: String) -> String {
        String(source.prefix { $0 == " " || $0 == "\t" })
    }
}
