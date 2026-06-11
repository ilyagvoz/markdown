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

    func testWorkspaceSearchFileIncludesFileContext() {
        let analyzer = MarkdownDocumentAnalyzer()
        let fileURL = URL(fileURLWithPath: "/tmp/workspace/notes/install.md")

        let results = analyzer.searchWorkspaceFile(
            fileURL: fileURL,
            relativePath: "notes/install.md",
            markdown: """
            # Install

            Searchable setup step.
            Another searchable setup step.
            """,
            query: "searchable"
        )

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].fileURL, fileURL)
        XCTAssertEqual(results[0].fileName, "install.md")
        XCTAssertEqual(results[0].relativePath, "notes/install.md")
        XCTAssertEqual(results[0].headingContext, "Install")
        XCTAssertEqual(results[0].occurrence, 0)
        XCTAssertEqual(results[1].occurrence, 1)
    }

    func testWorkspaceSearchFileHonorsLimitAndTruncatesSnippetAroundMatch() {
        let analyzer = MarkdownDocumentAnalyzer()
        let longPrefix = String(repeating: "prefix ", count: 30)
        let longSuffix = String(repeating: " suffix", count: 30)

        let results = analyzer.searchWorkspaceFile(
            fileURL: URL(fileURLWithPath: "/tmp/workspace/large.md"),
            relativePath: "large.md",
            markdown: """
            \(longPrefix)needle\(longSuffix)
            needle second
            needle third
            """,
            query: "needle",
            limit: 2
        )

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results[0].snippet.hasPrefix("..."))
        XCTAssertTrue(results[0].snippet.contains("needle"))
        XCTAssertTrue(results[0].snippet.hasSuffix("..."))
    }
}
