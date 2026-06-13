import MarkdownCore
import XCTest

final class MarkdownHTMLRendererTests: XCTestCase {
    func testRendersCommonMarkdownToSemanticHTML() {
        let renderer = MarkdownHTMLRenderer()
        let rendered = renderer.render(markdown: """
        # Title

        Paragraph with **strong text** and `code`.

        - One
        - Two

        | A | B |
        |---|---|
        | 1 | 2 |
        """)

        XCTAssertEqual(rendered.title, "Title")
        XCTAssertTrue(rendered.html.contains("<h1 id=\"title\">Title</h1>"))
        XCTAssertTrue(rendered.html.contains("<strong>strong text</strong>"))
        XCTAssertTrue(rendered.html.contains("<code>code</code>"))
        XCTAssertTrue(rendered.html.contains("<ul>"))
        XCTAssertTrue(rendered.html.contains("<table>"))
        XCTAssertEqual(rendered.outline.first?.title, "Title")
    }

    func testWrapsReadableLightOnlyCSS() {
        let renderer = MarkdownHTMLRenderer()
        let rendered = renderer.render(markdown: "# Title")

        XCTAssertTrue(rendered.html.contains("color-scheme: light"))
        XCTAssertTrue(rendered.html.contains("\"New York\""))
        XCTAssertTrue(rendered.html.contains("max-width: 780px"))
        XCTAssertTrue(rendered.html.contains("ul, ol { padding-left: 1.18em; }"))
        XCTAssertTrue(rendered.html.contains("p:has(+ ul)"))
        XCTAssertTrue(rendered.html.contains("p:has(+ ol)"))
        XCTAssertTrue(rendered.html.contains("margin-bottom: 0.30em;"))
        XCTAssertFalse(rendered.html.contains("margin-top: -0.75em;"))
    }

    func testAddsOutlineAnchorsForDocumentLandmarks() {
        let renderer = MarkdownHTMLRenderer()
        let rendered = renderer.render(markdown: """
        # Guide

        ## Section

        | A | B |
        |---|---|
        | 1 | 2 |

        ```mermaid
        graph TD
        ```
        """)

        XCTAssertTrue(rendered.html.contains("id=\"guide\""))
        XCTAssertTrue(rendered.html.contains("id=\"section\""))
        XCTAssertTrue(rendered.html.contains("class=\"md-anchor\"></span><table>"))
        XCTAssertTrue(rendered.outline.contains { $0.kind == .table })
        XCTAssertTrue(rendered.outline.contains { $0.kind == .diagram })
    }

    func testRendersTableHeadersBodyAndAlignment() {
        let renderer = MarkdownHTMLRenderer()
        let rendered = renderer.render(markdown: """
        | Feature | Native | WebView |
        |---|---:|---:|
        | Text selection | TBD | TBD |
        | Markdown fidelity | TBD | TBD |
        """)

        XCTAssertTrue(rendered.html.contains("<thead>"))
        XCTAssertTrue(rendered.html.contains("<tbody>"))
        XCTAssertTrue(rendered.html.contains("<th>Feature</th>"))
        XCTAssertTrue(rendered.html.contains(#"<th align="right">Native</th>"#))
        XCTAssertTrue(rendered.html.contains(#"<td align="right">TBD</td>"#))
        XCTAssertFalse(rendered.html.contains("|---|---:|---:|"))
    }

    func testRendersRawHTMLAsText() {
        let renderer = MarkdownHTMLRenderer()
        let rendered = renderer.render(markdown: """
        <script>alert("nope")</script>

        Paragraph with <img src=x onerror=alert(1)> inline HTML.
        """)

        XCTAssertFalse(rendered.html.contains("<script>alert"))
        XCTAssertFalse(rendered.html.contains("<img src=x"))
        XCTAssertTrue(rendered.html.contains("&lt;script&gt;alert(\"nope\")&lt;/script&gt;"))
        XCTAssertTrue(rendered.html.contains("&lt;img src=x onerror=alert(1)&gt;"))
    }
}
