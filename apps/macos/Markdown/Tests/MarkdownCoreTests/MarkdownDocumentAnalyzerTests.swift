import MarkdownCore
import XCTest

final class MarkdownDocumentAnalyzerTests: XCTestCase {
    func testExtractsHeadingsAndLandmarks() {
        let analyzer = MarkdownDocumentAnalyzer()
        let outline = analyzer.outline(for: """
        # Guide

        ## Install

        > Important note.

        | Name | Value |
        |---|---|
        | A | B |

        ![Diagram preview](diagram.png)

        ```swift
        let value = 1
        ```

        ```mermaid
        graph TD
        ```
        """)

        XCTAssertEqual(outline.map(\.kind), [.heading, .heading, .blockQuote, .table, .image, .codeBlock, .diagram])
        XCTAssertEqual(outline[0].id, "guide")
        XCTAssertEqual(outline[1].id, "install")
        XCTAssertEqual(outline[1].level, 2)
    }

    func testSearchReturnsHeadingContextAndOccurrence() {
        let analyzer = MarkdownDocumentAnalyzer()
        let results = analyzer.search(markdown: """
        # Guide

        First paragraph.

        ## Details

        Searchable detail.
        Another searchable detail.
        """, query: "searchable")

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].headingContext, "Details")
        XCTAssertEqual(results[0].occurrence, 0)
        XCTAssertEqual(results[1].occurrence, 1)
    }
}
