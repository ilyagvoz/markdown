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
        XCTAssertTrue(html.contains("saveRequested"))
    }
}
