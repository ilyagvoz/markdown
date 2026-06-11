import MarkdownAppSupport
import XCTest

final class MarkdownEditorHTMLTests: XCTestCase {
    func testEmbedsMarkdownAsEscapedJavaScriptString() {
        let html = MarkdownEditorHTML.document(markdown: "# Title\nquote \" slash \\", title: "Doc")

        XCTAssertTrue(html.contains("window.initialMarkdown = \"# Title\\nquote \\\" slash \\\\\";"))
    }

    func testIncludesLivePreviewEditingBehaviors() {
        let html = MarkdownEditorHTML.document(markdown: "- Item", title: "Doc")

        XCTAssertTrue(html.contains("function splitBlockAtCaret"))
        XCTAssertTrue(html.contains("function markerSelectionRange"))
        XCTAssertTrue(html.contains("function inlineMarkdownHTML"))
        XCTAssertTrue(html.contains("shouldParseTypedSource"))
        XCTAssertTrue(html.contains("function undo()"))
        XCTAssertTrue(html.contains("function redo()"))
        XCTAssertTrue(html.contains("restoreHistorySnapshot"))
        XCTAssertTrue(html.contains("saveRequested"))
    }

    func testReadModeHidesMarkdownMarkersUntilLineIsUnlocked() {
        let html = MarkdownEditorHTML.document(markdown: "# Title\n- Item\n```swift\nlet value = 1\n```", title: "Doc")
        let compactHTML = html.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        XCTAssertTrue(compactHTML.contains(".editor-marker { display: none;"))
        XCTAssertTrue(html.contains(".editor-block-fence:not(.editor-block-unlocked)"))
        XCTAssertTrue(html.contains(".editor-block-unlocked"))
        XCTAssertTrue(html.contains("function markerViewText"))
        XCTAssertTrue(html.contains(".editor-block-blank:focus-within"))
        XCTAssertTrue(html.contains("editor-block-code-start"))
        XCTAssertTrue(html.contains("editor-block-code-end"))
        XCTAssertTrue(html.contains("border-top-width: 0;"))
    }
}
