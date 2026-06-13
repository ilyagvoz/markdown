import MarkdownAppSupport
import XCTest

final class DefaultMarkdownReaderRegistrationTests: XCTestCase {
    func testRegistersStandardMarkdownContentType() {
        XCTAssertEqual(DefaultMarkdownReaderRegistration.markdownContentTypes, ["net.daringfireball.markdown"])
    }

    func testMissingBundleIdentifierReturnsUserFacingError() {
        let result = DefaultMarkdownReaderRegistration.makeDefaultReader(bundleIdentifier: "")

        guard case .failure(.missingBundleIdentifier) = result else {
            return XCTFail("Expected missing bundle identifier error")
        }
        XCTAssertEqual(
            RegistrationError.missingBundleIdentifier.userMessage,
            "Markdown could not find its app identifier."
        )
    }
}
