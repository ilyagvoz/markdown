import Foundation

public enum DocumentOutlineKind: String, Sendable {
    case heading
    case table
    case codeBlock
    case blockQuote
    case image
    case diagram
}

public struct DocumentOutlineItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let kind: DocumentOutlineKind
    public let level: Int
    public let lineNumber: Int

    public init(id: String, title: String, kind: DocumentOutlineKind, level: Int, lineNumber: Int) {
        self.id = id
        self.title = title
        self.kind = kind
        self.level = level
        self.lineNumber = lineNumber
    }
}

public struct DocumentSearchResult: Identifiable, Equatable, Sendable {
    public let id: String
    public let lineNumber: Int
    public let headingContext: String?
    public let snippet: String
    public let occurrence: Int

    public init(id: String, lineNumber: Int, headingContext: String?, snippet: String, occurrence: Int) {
        self.id = id
        self.lineNumber = lineNumber
        self.headingContext = headingContext
        self.snippet = snippet
        self.occurrence = occurrence
    }
}

public struct WorkspaceSearchResult: Identifiable, Equatable, Sendable {
    public let id: String
    public let fileURL: URL
    public let fileName: String
    public let relativePath: String
    public let lineNumber: Int
    public let headingContext: String?
    public let snippet: String
    public let occurrence: Int

    public init(
        id: String,
        fileURL: URL,
        fileName: String,
        relativePath: String,
        lineNumber: Int,
        headingContext: String?,
        snippet: String,
        occurrence: Int
    ) {
        self.id = id
        self.fileURL = fileURL
        self.fileName = fileName
        self.relativePath = relativePath
        self.lineNumber = lineNumber
        self.headingContext = headingContext
        self.snippet = snippet
        self.occurrence = occurrence
    }
}

public struct MarkdownDocumentAnalyzer: Sendable {
    public init() {}

    public func outline(for markdown: String) -> [DocumentOutlineItem] {
        var items: [DocumentOutlineItem] = []
        var anchorCounts: [String: Int] = [:]
        var inFence = false
        var fenceStartLine = 0
        var fenceLanguage = ""
        var blockQuoteOpen = false
        var previousLineWasTableSeparator = false

        let lines = markdown.components(separatedBy: .newlines)
        for (offset, line) in lines.enumerated() {
            let lineNumber = offset + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                if inFence {
                    inFence = false
                } else {
                    inFence = true
                    fenceStartLine = lineNumber
                    fenceLanguage = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                    let kind: DocumentOutlineKind = fenceLanguage.lowercased() == "mermaid" ? .diagram : .codeBlock
                    let title = kind == .diagram ? "Diagram" : codeTitle(language: fenceLanguage)
                    items.append(item(title: title, kind: kind, level: 2, lineNumber: fenceStartLine, counts: &anchorCounts))
                }
                continue
            }

            guard !inFence else { continue }

            if let heading = parseHeading(trimmed) {
                items.append(item(title: heading.title, kind: .heading, level: heading.level, lineNumber: lineNumber, counts: &anchorCounts))
                blockQuoteOpen = false
                previousLineWasTableSeparator = false
                continue
            }

            if let imageTitle = parseImageTitle(trimmed) {
                items.append(item(title: imageTitle, kind: .image, level: 2, lineNumber: lineNumber, counts: &anchorCounts))
                blockQuoteOpen = false
                previousLineWasTableSeparator = false
                continue
            }

            if trimmed.hasPrefix(">") {
                if !blockQuoteOpen {
                    items.append(item(title: "Quote", kind: .blockQuote, level: 2, lineNumber: lineNumber, counts: &anchorCounts))
                }
                blockQuoteOpen = true
                previousLineWasTableSeparator = false
                continue
            } else if !trimmed.isEmpty {
                blockQuoteOpen = false
            }

            if isTableSeparator(trimmed) {
                previousLineWasTableSeparator = true
                continue
            }

            if previousLineWasTableSeparator, looksLikeTableRow(trimmed) {
                items.append(item(title: "Table", kind: .table, level: 2, lineNumber: max(1, lineNumber - 2), counts: &anchorCounts))
                previousLineWasTableSeparator = false
                continue
            }

            previousLineWasTableSeparator = false
        }

        return items
    }

    public func search(markdown: String, query: String, limit: Int = 80) -> [DocumentSearchResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }

        let lines = markdown.components(separatedBy: .newlines)
        var results: [DocumentSearchResult] = []
        var currentHeading: String?
        var occurrence = 0

        for (offset, line) in lines.enumerated() {
            let lineNumber = offset + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let heading = parseHeading(trimmed) {
                currentHeading = heading.title
            }

            guard line.range(of: normalizedQuery, options: [.caseInsensitive, .diacriticInsensitive]) != nil else {
                continue
            }

            results.append(DocumentSearchResult(
                id: "search-\(lineNumber)-\(occurrence)",
                lineNumber: lineNumber,
                headingContext: currentHeading,
                snippet: snippet(from: line, query: normalizedQuery),
                occurrence: occurrence
            ))
            occurrence += 1

            if results.count >= limit {
                break
            }
        }

        return results
    }

    public func searchWorkspaceFile(
        fileURL: URL,
        relativePath: String,
        markdown: String,
        query: String,
        limit: Int = 12
    ) -> [WorkspaceSearchResult] {
        search(markdown: markdown, query: query, limit: limit).map { result in
            WorkspaceSearchResult(
                id: "\(fileURL.standardizedFileURL.path)-\(result.lineNumber)-\(result.occurrence)",
                fileURL: fileURL.standardizedFileURL,
                fileName: fileURL.lastPathComponent,
                relativePath: relativePath,
                lineNumber: result.lineNumber,
                headingContext: result.headingContext,
                snippet: result.snippet,
                occurrence: result.occurrence
            )
        }
    }

    private func item(
        title: String,
        kind: DocumentOutlineKind,
        level: Int,
        lineNumber: Int,
        counts: inout [String: Int]
    ) -> DocumentOutlineItem {
        let base = slug(title.isEmpty ? kind.rawValue : title)
        let count = counts[base, default: 0]
        counts[base] = count + 1
        let id = count == 0 ? base : "\(base)-\(count + 1)"
        return DocumentOutlineItem(id: id, title: title, kind: kind, level: level, lineNumber: lineNumber)
    }

    private func parseHeading(_ line: String) -> (level: Int, title: String)? {
        guard line.hasPrefix("#") else { return nil }
        let markerCount = line.prefix { $0 == "#" }.count
        guard (1...6).contains(markerCount) else { return nil }
        let markerEnd = line.index(line.startIndex, offsetBy: markerCount)
        guard markerEnd < line.endIndex, line[markerEnd].isWhitespace else { return nil }
        let rawTitle = line[markerEnd...].trimmingCharacters(in: .whitespaces)
        let title = rawTitle.replacingOccurrences(of: #"\s+#+\s*$"#, with: "", options: .regularExpression)
        return (markerCount, title)
    }

    private func parseImageTitle(_ line: String) -> String? {
        guard line.hasPrefix("!["),
              let close = line.firstIndex(of: "]")
        else {
            return nil
        }
        let altStart = line.index(line.startIndex, offsetBy: 2)
        let alt = String(line[altStart..<close]).trimmingCharacters(in: .whitespaces)
        return alt.isEmpty ? "Image" : "Image: \(alt)"
    }

    private func codeTitle(language: String) -> String {
        language.isEmpty ? "Code Block" : "Code: \(language)"
    }

    private func isTableSeparator(_ line: String) -> Bool {
        guard line.contains("|") else { return false }
        let allowed = CharacterSet(charactersIn: "|-: ")
        return !line.isEmpty && line.unicodeScalars.allSatisfy { allowed.contains($0) } && line.contains("-")
    }

    private func looksLikeTableRow(_ line: String) -> Bool {
        line.contains("|") && !line.trimmingCharacters(in: CharacterSet(charactersIn: "| ")).isEmpty
    }

    private func snippet(from line: String, query: String) -> String {
        let cleaned = line.trimmingCharacters(in: .whitespaces)
        guard cleaned.count > 140 else { return cleaned }
        guard let range = cleaned.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) else {
            return String(cleaned.prefix(137)) + "..."
        }
        let lower = cleaned.distance(from: cleaned.startIndex, to: range.lowerBound)
        let startOffset = max(0, lower - 48)
        let start = cleaned.index(cleaned.startIndex, offsetBy: startOffset)
        let end = cleaned.index(start, offsetBy: min(137, cleaned.distance(from: start, to: cleaned.endIndex)))
        let prefix = start == cleaned.startIndex ? "" : "..."
        let suffix = end == cleaned.endIndex ? "" : "..."
        return prefix + cleaned[start..<end] + suffix
    }

    private func slug(_ value: String) -> String {
        let lower = value.lowercased()
        let mapped = lower.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) {
                return Character(scalar)
            }
            return "-"
        }
        let collapsed = String(mapped)
            .replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return collapsed.isEmpty ? "section" : collapsed
    }
}
