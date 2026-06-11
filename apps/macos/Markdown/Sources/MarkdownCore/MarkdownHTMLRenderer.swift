import Foundation
import Markdown

public struct RenderedMarkdown: Equatable, Sendable {
    public let title: String?
    public let html: String
    public let outline: [DocumentOutlineItem]

    public init(title: String?, html: String, outline: [DocumentOutlineItem]) {
        self.title = title
        self.html = html
        self.outline = outline
    }
}

public struct MarkdownHTMLRenderer: Sendable {
    private let analyzer = MarkdownDocumentAnalyzer()

    public init() {}

    public func render(markdown: String, sourceURL: URL? = nil) -> RenderedMarkdown {
        let document = Document(parsing: markdown)
        let outline = analyzer.outline(for: markdown)
        let title = outline.first(where: { $0.kind == .heading })?.title ?? firstHeading(in: document)
        let body = addAnchors(to: HTMLFormatter.format(document), outline: outline)
        return RenderedMarkdown(
            title: title,
            html: wrap(body: body, title: title ?? sourceURL?.deletingPathExtension().lastPathComponent ?? "Markdown"),
            outline: outline
        )
    }

    private func firstHeading(in document: Document) -> String? {
        for child in document.children {
            if let heading = child as? Heading {
                return heading.plainText
            }
        }
        return nil
    }

    private func wrap(body: String, title: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(escapeHTML(title))</title>
          <style>
            :root {
              color-scheme: light;
              --page: #fbfaf6;
              --text: #24231f;
              --muted: #6d6a61;
              --rule: rgba(36, 35, 31, 0.14);
              --code-bg: #f1eee7;
              --quote: #3a6b68;
              --accent: #006b7a;
              --table-stripe: rgba(0, 107, 122, 0.055);
              --shadow: rgba(31, 35, 40, 0.08);
            }

            html {
              background: var(--page);
              text-rendering: optimizeLegibility;
              -webkit-font-smoothing: antialiased;
            }

            body {
              margin: 0;
              padding: 46px 56px 78px;
              color: var(--text);
              background: var(--page);
              font-family: "New York", "Iowan Old Style", Charter, ui-serif, Georgia, serif;
              font-size: 18px;
              line-height: 1.72;
            }

            main {
              max-width: 780px;
              margin: 0 auto;
            }

            h1, h2, h3, h4, h5, h6 {
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
              line-height: 1.18;
              margin: 1.65em 0 0.45em;
              color: var(--text);
              font-weight: 730;
            }

            h1 {
              font-size: 2.4rem;
              letter-spacing: 0;
              margin-top: 0;
              margin-bottom: 0.62em;
            }

            h2 {
              font-size: 1.62rem;
              margin-top: 1.9em;
            }

            h3 { font-size: 1.28rem; }
            h4, h5, h6 { font-size: 1.05rem; }

            p, ul, ol, blockquote, pre, table {
              margin-top: 0;
              margin-bottom: 1.05em;
            }

            a {
              color: var(--accent);
              text-decoration-thickness: 0.08em;
              text-underline-offset: 0.18em;
            }

            ul, ol { padding-left: 1.45em; }
            li + li { margin-top: 0.18em; }
            li > p { margin-bottom: 0.35em; }

            blockquote {
              margin-left: 0;
              padding: 0.18em 0 0.18em 1.05em;
              color: var(--muted);
              border-left: 4px solid var(--quote);
            }

            code {
              font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
              font-size: 0.88em;
              padding: 0.12em 0.32em;
              border-radius: 5px;
              background: var(--code-bg);
            }

            pre {
              overflow-x: auto;
              padding: 1em 1.1em;
              border-radius: 8px;
              background: var(--code-bg);
              border: 1px solid var(--rule);
              box-shadow: 0 8px 24px var(--shadow);
            }

            pre code {
              display: block;
              padding: 0;
              border-radius: 0;
              background: transparent;
              line-height: 1.55;
            }

            table {
              width: 100%;
              border-collapse: collapse;
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
              font-size: 0.92em;
              line-height: 1.45;
            }

            th, td {
              padding: 0.55em 0.7em;
              border-bottom: 1px solid var(--rule);
              vertical-align: top;
            }

            th {
              text-align: left;
              font-weight: 680;
              color: var(--text);
            }

            tbody tr:nth-child(odd) {
              background: var(--table-stripe);
            }

            hr {
              border: 0;
              border-top: 1px solid var(--rule);
              margin: 2em 0;
            }

            img {
              max-width: 100%;
              height: auto;
              border-radius: 8px;
            }

            .md-anchor {
              position: relative;
              top: -18px;
              display: block;
              height: 0;
              overflow: hidden;
            }

            .md-search-hit {
              border-radius: 4px;
              background: rgba(255, 214, 102, 0.58);
              box-shadow: 0 0 0 2px rgba(255, 214, 102, 0.32);
            }

            @media (max-width: 720px) {
              body {
                padding: 28px 24px 56px;
                font-size: 17px;
              }

              h1 { font-size: 2rem; }
              h2 { font-size: 1.45rem; }
            }
          </style>
          <script>
            window.markdownClearSearchHighlights = function() {
              document.querySelectorAll('.md-search-hit').forEach(function(node) {
                var parent = node.parentNode;
                while (node.firstChild) parent.insertBefore(node.firstChild, node);
                parent.removeChild(node);
                parent.normalize();
              });
            };

            window.markdownJumpTo = function(id) {
              var target = document.getElementById(id);
              if (!target) return false;
              target.scrollIntoView({ block: 'start', behavior: 'smooth' });
              return true;
            };

            window.markdownFindText = function(query, occurrence) {
              window.markdownClearSearchHighlights();
              if (!query) return false;
              var needle = query.toLocaleLowerCase();
              var walker = document.createTreeWalker(document.querySelector('main'), NodeFilter.SHOW_TEXT);
              var node;
              var index = 0;
              while ((node = walker.nextNode())) {
                var haystack = node.nodeValue.toLocaleLowerCase();
                var found = haystack.indexOf(needle);
                if (found === -1) continue;
                if (index !== occurrence) {
                  index += 1;
                  continue;
                }
                var range = document.createRange();
                range.setStart(node, found);
                range.setEnd(node, found + query.length);
                var mark = document.createElement('mark');
                mark.className = 'md-search-hit';
                range.surroundContents(mark);
                mark.scrollIntoView({ block: 'center', behavior: 'smooth' });
                return true;
              }
              return false;
            };
          </script>
        </head>
        <body>
          <main>
        \(body)
          </main>
        </body>
        </html>
        """
    }

    private func escapeHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private func addAnchors(to html: String, outline: [DocumentOutlineItem]) -> String {
        var anchored = addHeadingAnchors(to: html, headings: outline.filter { $0.kind == .heading })
        anchored = insertAnchors(into: anchored, items: outline.filter { $0.kind == .table }, beforeTag: "table")
        anchored = insertAnchors(into: anchored, items: outline.filter { $0.kind == .codeBlock || $0.kind == .diagram }, beforeTag: "pre")
        anchored = insertAnchors(into: anchored, items: outline.filter { $0.kind == .blockQuote }, beforeTag: "blockquote")
        anchored = insertAnchors(into: anchored, items: outline.filter { $0.kind == .image }, beforeTag: "img")
        return anchored
    }

    private func addHeadingAnchors(to html: String, headings: [DocumentOutlineItem]) -> String {
        guard !headings.isEmpty else { return html }
        let pattern = #"<h([1-6])>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return html }
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, range: nsRange)
        var result = html
        var headingIndex = min(matches.count, headings.count) - 1

        for match in matches.prefix(headings.count).reversed() {
            guard let range = Range(match.range, in: result), headingIndex >= 0 else { continue }
            let level = result[range].dropFirst(2).dropLast()
            result.replaceSubrange(range, with: "<h\(level) id=\"\(escapeHTML(headings[headingIndex].id))\">")
            headingIndex -= 1
        }

        return result
    }

    private func insertAnchors(into html: String, items: [DocumentOutlineItem], beforeTag tag: String) -> String {
        guard !items.isEmpty else { return html }
        let pattern = #"<\#(tag)(\s|>|/)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return html }
        var result = html
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..<html.endIndex, in: html))

        for (item, match) in zip(items, matches).reversed() {
            guard let range = Range(NSRange(location: match.range.location, length: 0), in: result) else { continue }
            result.insert(contentsOf: "<span id=\"\(escapeHTML(item.id))\" class=\"md-anchor\"></span>", at: range.lowerBound)
        }

        return result
    }
}
