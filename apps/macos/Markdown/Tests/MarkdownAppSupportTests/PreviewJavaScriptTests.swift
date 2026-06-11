import MarkdownAppSupport
import XCTest

final class PreviewJavaScriptTests: XCTestCase {
    func testStringLiteralEncodesTopLevelStringWithoutThrowing() {
        XCTAssertEqual(PreviewJavaScript.stringLiteral("section"), "\"section\"")
    }

    func testStringLiteralEscapesJavaScriptSensitiveCharacters() {
        let literal = PreviewJavaScript.stringLiteral("quote \" newline\nslash \\")

        XCTAssertTrue(literal.hasPrefix("\""))
        XCTAssertTrue(literal.hasSuffix("\""))
        XCTAssertTrue(literal.contains("\\\""))
        XCTAssertTrue(literal.contains("\\n"))
        XCTAssertTrue(literal.contains("\\\\"))
    }

    func testBuildsOutlineJumpScript() {
        XCTAssertEqual(
            PreviewJavaScript.jumpToAnchorScript(anchorID: "nested-heading"),
            "window.markdownJumpTo(\"nested-heading\");"
        )
    }

    func testBuildsSearchJumpScript() {
        XCTAssertEqual(
            PreviewJavaScript.findTextScript(query: "diagram", occurrence: 2),
            "window.markdownFindText(\"diagram\", 2);"
        )
    }
}
