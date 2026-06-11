import EditingSpike
import XCTest

final class MarkdownLineModelTests: XCTestCase {
    func testRoundTripsCommonMarkdownWithoutEdits() {
        let markdown = """
        # Guide

        Paragraph text.

        - First item
        1. Ordered item
        > Quote text

        ```swift
        let value = 1
        ```

        | A | B |
        |---|---|
        | 1 | 2 |
        """

        let document = MarkdownLineDocument(markdown: markdown)

        XCTAssertEqual(document.serialized(), markdown)
    }

    func testHeadingEditPreservesHeadingPresentation() {
        var document = MarkdownLineDocument(markdown: "## Old Heading")

        document.replaceVisibleText(at: 0, with: "New Heading")

        XCTAssertEqual(document.lines[0].presentation, .heading(level: 2))
        XCTAssertEqual(document.lines[0].visibleText, "New Heading")
        XCTAssertEqual(document.serialized(), "## New Heading")
    }

    func testListEditPreservesListMarker() {
        var unordered = MarkdownLineDocument(markdown: "- Old item")
        var ordered = MarkdownLineDocument(markdown: "12. Old item")

        unordered.replaceVisibleText(at: 0, with: "New item")
        ordered.replaceVisibleText(at: 0, with: "New item")

        XCTAssertEqual(unordered.lines[0].presentation, .unorderedList(marker: "-"))
        XCTAssertEqual(unordered.serialized(), "- New item")
        XCTAssertEqual(ordered.lines[0].presentation, .orderedList(marker: "12."))
        XCTAssertEqual(ordered.serialized(), "12. New item")
    }

    func testQuoteEditPreservesQuoteMarker() {
        var document = MarkdownLineDocument(markdown: "> Old quote")

        document.replaceVisibleText(at: 0, with: "New quote")

        XCTAssertEqual(document.lines[0].presentation, .quote)
        XCTAssertEqual(document.serialized(), "> New quote")
    }

    func testCodeContentEditPreservesRawCodeLine() {
        var document = MarkdownLineDocument(markdown: """
        ```swift
        let value = 1
        ```
        """)

        document.replaceVisibleText(at: 1, with: "let value = 2")

        XCTAssertEqual(document.lines[1].presentation, .codeContent)
        XCTAssertEqual(document.serialized(), """
        ```swift
        let value = 2
        ```
        """)
    }

    func testFenceLanguageEditPreservesFenceMarker() {
        var document = MarkdownLineDocument(markdown: "```swift")

        document.replaceVisibleText(at: 0, with: "mermaid")

        XCTAssertEqual(document.lines[0].presentation, .fencedCode(marker: "```"))
        XCTAssertEqual(document.serialized(), "```mermaid")
    }

    func testUnlockedSourceExposesMarkdownMarkersForIntentionalTypeChange() {
        let heading = MarkdownLineDocument(markdown: "### Title").lines[0]
        let item = MarkdownLineDocument(markdown: "- Item").lines[0]
        let quote = MarkdownLineDocument(markdown: "> Quote").lines[0]

        XCTAssertEqual(heading.visibleText, "Title")
        XCTAssertEqual(heading.unlockedSource, "### Title")
        XCTAssertEqual(item.visibleText, "Item")
        XCTAssertEqual(item.unlockedSource, "- Item")
        XCTAssertEqual(quote.visibleText, "Quote")
        XCTAssertEqual(quote.unlockedSource, "> Quote")
    }
}
