import NativeWebViewEditorSpikeSupport
import XCTest

final class EditorBridgeMessageTests: XCTestCase {
    func testParsesReadyMessage() {
        let message = EditorBridgeMessageParser.parse(["type": "ready"])

        XCTAssertEqual(message, EditorBridgeMessage(type: .ready))
        XCTAssertEqual(message.map(EditorBridgeMessageParser.statusText), "Editor ready")
    }

    func testParsesDocumentChangedMarkdownPayload() {
        let message = EditorBridgeMessageParser.parse([
            "type": "documentChanged",
            "markdown": "# Edited"
        ])

        XCTAssertEqual(
            message,
            EditorBridgeMessage(type: .documentChanged, markdown: "# Edited")
        )
        XCTAssertEqual(message.map(EditorBridgeMessageParser.statusText), "Document changed (8 bytes)")
    }

    func testParsesRoutedShortcutMessage() {
        let message = EditorBridgeMessageParser.parse([
            "type": "shortcut",
            "route": "native-navigation",
            "key": "ArrowDown"
        ])

        XCTAssertEqual(
            message,
            EditorBridgeMessage(type: .shortcut, route: "native-navigation", key: "ArrowDown")
        )
        XCTAssertEqual(
            message.map(EditorBridgeMessageParser.statusText),
            "Shortcut ArrowDown routed to native-navigation"
        )
    }

    func testRejectsMalformedMessages() {
        XCTAssertNil(EditorBridgeMessageParser.parse(["markdown": "# Missing type"]))
        XCTAssertNil(EditorBridgeMessageParser.parse(["type": "not-supported"]))
        XCTAssertNil(EditorBridgeMessageParser.parse("not a JSON object"))
    }
}
