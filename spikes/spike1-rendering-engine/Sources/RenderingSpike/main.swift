import AppKit
import Foundation
import MachO
import Markdown
import WebKit

struct Fixture {
    let name: String
    let markdown: String
}

struct Measurement {
    let fixture: String
    let renderer: String
    let runs: [Double]
    let memoryBefore: UInt64
    let memoryAfter: UInt64

    var medianMs: Double {
        let sorted = runs.sorted()
        guard !sorted.isEmpty else { return 0 }
        return sorted[sorted.count / 2]
    }

    var minMs: Double {
        runs.min() ?? 0
    }

    var maxMs: Double {
        runs.max() ?? 0
    }
}

enum SpikeError: Error {
    case missingFixtures(URL)
    case htmlConversionFailed
    case webViewNavigationFailed(Error)
}

@MainActor
final class NativeAttributedRenderer {
    private let textView: NSTextView
    private let builder = NativeAttributedDocumentBuilder()

    init() {
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 900, height: 1200))
        textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainer?.containerSize = NSSize(width: 900, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        scrollView.documentView = textView
    }

    func render(_ markdown: String) throws {
        let document = Document(parsing: markdown)
        let attributed = builder.render(document)

        textView.textStorage?.setAttributedString(attributed)
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
    }
}

@MainActor
final class WebViewRenderer: NSObject, WKNavigationDelegate {
    private let webView: WKWebView
    private var continuation: CheckedContinuation<Void, Error>?

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 1200), configuration: configuration)
        super.init()
        webView.navigationDelegate = self
    }

    func render(_ markdown: String) async throws {
        let document = Document(parsing: markdown)
        let html = htmlDocument(from: document)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.continuation = continuation
            self.webView.loadHTMLString(html, baseURL: nil)
        }
    }

    private func htmlDocument(from document: Document) -> String {
        let body = HTMLFormatter.format(document)

        return """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            :root { color-scheme: light dark; }
            body {
              margin: 0;
              padding: 32px 40px;
              font: -apple-system-body;
              line-height: 1.5;
              color: CanvasText;
              background: Canvas;
            }
            pre, code {
              font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
              font-size: 0.92em;
            }
            pre {
              padding: 12px;
              overflow-x: auto;
              border: 1px solid color-mix(in srgb, CanvasText 18%, transparent);
              border-radius: 6px;
            }
            blockquote {
              margin-left: 0;
              padding-left: 16px;
              border-left: 3px solid color-mix(in srgb, CanvasText 24%, transparent);
              color: color-mix(in srgb, CanvasText 78%, transparent);
            }
            img { max-width: 100%; height: auto; }
          </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            continuation?.resume()
            continuation = nil
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: SpikeError.webViewNavigationFailed(error))
            continuation = nil
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: SpikeError.webViewNavigationFailed(error))
            continuation = nil
        }
    }
}

final class NativeAttributedDocumentBuilder {
    private let bodyFont = NSFont.systemFont(ofSize: 15)
    private let boldFont = NSFont.boldSystemFont(ofSize: 15)
    private let italicFont = NSFontManager.shared.convert(NSFont.systemFont(ofSize: 15), toHaveTrait: .italicFontMask)
    private let monoFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    private let headingFonts: [Int: NSFont] = [
        1: NSFont.boldSystemFont(ofSize: 30),
        2: NSFont.boldSystemFont(ofSize: 24),
        3: NSFont.boldSystemFont(ofSize: 20),
        4: NSFont.boldSystemFont(ofSize: 17),
        5: NSFont.boldSystemFont(ofSize: 15),
        6: NSFont.boldSystemFont(ofSize: 14)
    ]

    func render(_ document: Document) -> NSAttributedString {
        let output = NSMutableAttributedString()
        for child in document.children {
            appendBlock(child, to: output, listDepth: 0, orderedIndex: nil)
        }
        return output
    }

    private func appendBlock(
        _ markup: Markup,
        to output: NSMutableAttributedString,
        listDepth: Int,
        orderedIndex: Int?
    ) {
        switch markup {
        case let heading as Heading:
            appendInlineChildren(
                of: heading,
                to: output,
                attributes: baseAttributes(
                    font: headingFonts[heading.level] ?? headingFonts[6]!,
                    paragraphSpacing: 12
                )
            )
            appendSpacing(to: output)

        case let paragraph as Paragraph:
            appendListPrefixIfNeeded(orderedIndex: orderedIndex, listDepth: listDepth, to: output)
            appendInlineChildren(of: paragraph, to: output, attributes: baseAttributes(paragraphSpacing: 10))
            appendSpacing(to: output)

        case let codeBlock as CodeBlock:
            let attributes = baseAttributes(
                font: monoFont,
                paragraphSpacing: 12,
                backgroundColor: NSColor.textBackgroundColor.withAlphaComponent(0.8)
            )
            output.append(NSAttributedString(string: codeBlock.code + "\n\n", attributes: attributes))

        case let quote as BlockQuote:
            let quoteOutput = NSMutableAttributedString()
            for child in quote.children {
                appendBlock(child, to: quoteOutput, listDepth: listDepth, orderedIndex: nil)
            }
            let prefixed = quoteOutput.string
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { "│ \($0)" }
                .joined(separator: "\n")
            output.append(NSAttributedString(
                string: prefixed + "\n",
                attributes: baseAttributes(
                    paragraphSpacing: 10,
                    foregroundColor: NSColor.secondaryLabelColor
                )
            ))

        case let unordered as UnorderedList:
            for child in unordered.children {
                appendBlock(child, to: output, listDepth: listDepth + 1, orderedIndex: nil)
            }
            appendSpacing(to: output)

        case let ordered as OrderedList:
            var index = ordered.startIndex
            for child in ordered.children {
                appendBlock(child, to: output, listDepth: listDepth + 1, orderedIndex: Int(index))
                index += 1
            }
            appendSpacing(to: output)

        case let item as ListItem:
            for child in item.children {
                appendBlock(child, to: output, listDepth: listDepth, orderedIndex: orderedIndex)
            }

        case is ThematicBreak:
            output.append(NSAttributedString(string: "────────────\n\n", attributes: baseAttributes(paragraphSpacing: 12)))

        case let table as Table:
            output.append(NSAttributedString(
                string: plainText(from: table) + "\n\n",
                attributes: baseAttributes(font: monoFont, paragraphSpacing: 12)
            ))

        default:
            if markup.childCount > 0 {
                for child in markup.children {
                    appendBlock(child, to: output, listDepth: listDepth, orderedIndex: orderedIndex)
                }
            }
        }
    }

    private func appendInlineChildren(
        of markup: Markup,
        to output: NSMutableAttributedString,
        attributes: [NSAttributedString.Key: Any]
    ) {
        for child in markup.children {
            appendInline(child, to: output, attributes: attributes)
        }
    }

    private func appendInline(
        _ markup: Markup,
        to output: NSMutableAttributedString,
        attributes: [NSAttributedString.Key: Any]
    ) {
        switch markup {
        case let text as Text:
            output.append(NSAttributedString(string: text.string, attributes: attributes))

        case let strong as Strong:
            var next = attributes
            next[.font] = boldFont
            appendInlineChildren(of: strong, to: output, attributes: next)

        case let emphasis as Emphasis:
            var next = attributes
            next[.font] = italicFont
            appendInlineChildren(of: emphasis, to: output, attributes: next)

        case let inlineCode as InlineCode:
            var next = attributes
            next[.font] = monoFont
            next[.backgroundColor] = NSColor.textBackgroundColor.withAlphaComponent(0.9)
            output.append(NSAttributedString(string: inlineCode.code, attributes: next))

        case let link as Link:
            var next = attributes
            next[.foregroundColor] = NSColor.linkColor
            next[.underlineStyle] = NSUnderlineStyle.single.rawValue
            if let destination = link.destination {
                next[.link] = destination
            }
            appendInlineChildren(of: link, to: output, attributes: next)

        case let image as Image:
            let label = image.source.map { "[image: \($0)]" } ?? "[image]"
            output.append(NSAttributedString(string: label, attributes: attributes))

        case is SoftBreak:
            output.append(NSAttributedString(string: "\n", attributes: attributes))

        case is LineBreak:
            output.append(NSAttributedString(string: "\n", attributes: attributes))

        default:
            if markup.childCount > 0 {
                appendInlineChildren(of: markup, to: output, attributes: attributes)
            }
        }
    }

    private func appendListPrefixIfNeeded(
        orderedIndex: Int?,
        listDepth: Int,
        to output: NSMutableAttributedString
    ) {
        guard listDepth > 0 else { return }
        let indent = String(repeating: "  ", count: max(0, listDepth - 1))
        let marker = orderedIndex.map { "\($0)." } ?? "•"
        output.append(NSAttributedString(string: "\(indent)\(marker) ", attributes: baseAttributes()))
    }

    private func appendSpacing(to output: NSMutableAttributedString) {
        if !output.string.hasSuffix("\n\n") {
            output.append(NSAttributedString(string: "\n\n", attributes: baseAttributes()))
        }
    }

    private func baseAttributes(
        font: NSFont? = nil,
        paragraphSpacing: CGFloat = 8,
        foregroundColor: NSColor = .labelColor,
        backgroundColor: NSColor? = nil
    ) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2
        paragraph.paragraphSpacing = paragraphSpacing

        var attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? bodyFont,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraph
        ]

        if let backgroundColor {
            attributes[.backgroundColor] = backgroundColor
        }

        return attributes
    }

    private func plainText(from markup: Markup) -> String {
        switch markup {
        case let text as Text:
            return text.string
        case let code as InlineCode:
            return code.code
        case let codeBlock as CodeBlock:
            return codeBlock.code
        case let image as Image:
            return image.source.map { "[image: \($0)]" } ?? "[image]"
        case is Table.Row:
            return markup.children.map { plainText(from: $0) }.joined(separator: " | ") + "\n"
        default:
            return markup.children.map { plainText(from: $0) }.joined()
        }
    }
}

@main
@MainActor
struct RenderingSpike {
    static func main() async throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let fixtureURL = root.appending(path: "fixtures", directoryHint: .isDirectory)
        let fixtures = try loadFixtures(from: fixtureURL)
        let runs = 5

        print("# Rendering Engine Spike")
        print("")
        print("- Swift: \(swiftVersionDescription())")
        print("- Fixtures: \(fixtures.count)")
        print("- Runs per renderer/fixture: \(runs)")
        print("")

        let nativeRenderer = NativeAttributedRenderer()
        let webViewRenderer = WebViewRenderer()

        var measurements: [Measurement] = []
        for fixture in fixtures {
            let native = try await measure(
                fixture: fixture.name,
                renderer: "native-attributed-text",
                runs: runs
            ) {
                try nativeRenderer.render(fixture.markdown)
            }
            measurements.append(native)

            let web = try await measure(
                fixture: fixture.name,
                renderer: "webview-html",
                runs: runs
            ) {
                try await webViewRenderer.render(fixture.markdown)
            }
            measurements.append(web)
        }

        printTable(measurements)
        print("")
        print("Notes:")
        print("- Both prototypes parse Markdown through swift-markdown.")
        print("- Native numbers include AST parsing, a custom block-aware attributed-document pass, and NSTextView layout.")
        print("- WebView numbers include AST parsing, swift-markdown HTML formatting, and WKWebView load completion.")
        print("- Large fixture is synthetic, generated by repeating the checked-in large fixture.")
    }

    private static func loadFixtures(from directory: URL) throws -> [Fixture] {
        guard FileManager.default.fileExists(atPath: directory.path) else {
            throw SpikeError.missingFixtures(directory)
        }

        let urls = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
            .filter { $0.pathExtension == "md" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var fixtures = try urls.map { url in
            let markdown = try String(contentsOf: url, encoding: .utf8)
            return Fixture(name: url.lastPathComponent, markdown: markdown)
        }

        if let large = fixtures.first(where: { $0.name == "large.md" }) {
            let repeated = Array(repeating: large.markdown, count: 250).joined(separator: "\n\n")
            fixtures.append(Fixture(name: "large-synthetic.md", markdown: repeated))
        }

        return fixtures
    }

    @MainActor
    private static func measure(
        fixture: String,
        renderer: String,
        runs: Int,
        block: () async throws -> Void
    ) async throws -> Measurement {
        var timings: [Double] = []
        let memoryBefore = residentMemoryBytes()

        for _ in 0..<runs {
            let start = DispatchTime.now().uptimeNanoseconds
            try await block()
            let end = DispatchTime.now().uptimeNanoseconds
            timings.append(Double(end - start) / 1_000_000)
        }

        let memoryAfter = residentMemoryBytes()
        return Measurement(
            fixture: fixture,
            renderer: renderer,
            runs: timings,
            memoryBefore: memoryBefore,
            memoryAfter: memoryAfter
        )
    }

    private static func printTable(_ measurements: [Measurement]) {
        print("| Fixture | Renderer | Median ms | Min ms | Max ms | RSS Delta MB |")
        print("|---|---:|---:|---:|---:|---:|")
        for measurement in measurements {
            let delta = Int64(measurement.memoryAfter) - Int64(measurement.memoryBefore)
            let deltaMb = Double(delta) / 1_048_576
            print(
                "| \(measurement.fixture) | \(measurement.renderer) | \(format(measurement.medianMs)) | \(format(measurement.minMs)) | \(format(measurement.maxMs)) | \(format(deltaMb)) |"
            )
        }
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private static func residentMemoryBytes() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        return UInt64(info.resident_size)
    }

    private static func swiftVersionDescription() -> String {
        #if compiler(>=6.0)
        return "6.x"
        #else
        return "unknown"
        #endif
    }
}
