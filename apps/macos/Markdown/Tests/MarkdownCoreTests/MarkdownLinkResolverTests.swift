import MarkdownCore
import XCTest

final class MarkdownLinkResolverTests: XCTestCase {
    private var tempDirectory: URL!
    private var sourceFile: URL!
    private var resolver: MarkdownLinkResolver!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarkdownLinkResolverTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        sourceFile = tempDirectory.appendingPathComponent("Source.md")
        try write("# Source", to: sourceFile)
        resolver = MarkdownLinkResolver()
    }

    override func tearDownWithError() throws {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }

    func testResolvesHTTPAndHTTPSLinksAsExternalURLs() {
        XCTAssertEqual(
            resolver.resolve(href: "https://example.com/docs", documentURL: sourceFile),
            .externalURL(URL(string: "https://example.com/docs")!)
        )
        XCTAssertEqual(
            resolver.resolve(href: "http://example.com/docs", documentURL: sourceFile),
            .externalURL(URL(string: "http://example.com/docs")!)
        )
    }

    func testResolvesRelativeMarkdownFileWithFragment() throws {
        let target = tempDirectory.appendingPathComponent("Target.md")
        try write("# Target", to: target)

        XCTAssertEqual(
            resolver.resolve(href: "Target.md#details", documentURL: sourceFile),
            .markdownFile(fileURL: target.standardizedFileURL, fragment: "details")
        )
    }

    func testResolvesSameDocumentFragment() {
        XCTAssertEqual(
            resolver.resolve(href: "#local-heading", documentURL: sourceFile),
            .markdownFile(fileURL: sourceFile.standardizedFileURL, fragment: "local-heading")
        )
    }

    func testResolvesAbsoluteFileURL() throws {
        let target = tempDirectory.appendingPathComponent("Absolute.markdown")
        try write("# Absolute", to: target)

        XCTAssertEqual(
            resolver.resolve(href: target.absoluteString, documentURL: sourceFile),
            .markdownFile(fileURL: target.standardizedFileURL, fragment: nil)
        )
    }

    func testResolvesExtensionlessPathToExistingMarkdownCandidate() throws {
        let target = tempDirectory.appendingPathComponent("Guide.md")
        try write("# Guide", to: target)

        XCTAssertEqual(
            resolver.resolve(href: "Guide", documentURL: sourceFile),
            .markdownFile(fileURL: target.standardizedFileURL, fragment: nil)
        )
    }

    func testRejectsUnsupportedLocalFilesAndSchemes() throws {
        let pdf = tempDirectory.appendingPathComponent("Guide.pdf")
        try write("PDF", to: pdf)

        XCTAssertEqual(
            resolver.resolve(href: "Guide.pdf", documentURL: sourceFile),
            .unsupported(pdf.standardizedFileURL)
        )
        XCTAssertEqual(
            resolver.resolve(href: "javascript:alert(1)", documentURL: sourceFile),
            .unsupported(URL(string: "javascript:alert(1)")!)
        )
    }

    private func write(_ text: String, to url: URL) throws {
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
