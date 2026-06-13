import MarkdownAppSupport
import XCTest

final class MarkdownEditorHTMLTests: XCTestCase {
    func testEmbedsMarkdownAsEscapedJavaScriptString() {
        let html = MarkdownEditorHTML.document(markdown: "# Title\nquote \" slash \\", title: "Doc")

        XCTAssertTrue(html.contains("window.initialMarkdown = \"# Title\\nquote \\\" slash \\\\\";"))
    }

    func testCanEmitBaseURLForRelativeLocalImages() {
        let html = MarkdownEditorHTML.document(
            markdown: "![Image](image.png)",
            title: "Doc",
            baseURL: URL(fileURLWithPath: "/tmp/markdown images/")
        )

        XCTAssertTrue(html.contains(#"<base href="file:///tmp/markdown%20images/">"#))
    }

    func testIncludesLivePreviewEditingBehaviors() {
        let html = MarkdownEditorHTML.document(markdown: "- Item", title: "Doc")

        XCTAssertTrue(html.contains("function splitBlockAtCaret"))
        XCTAssertTrue(html.contains("function markerSelectionRange"))
        XCTAssertTrue(html.contains("function markerUnlockTarget"))
        XCTAssertTrue(html.contains("function codeLineExtractionTarget"))
        XCTAssertTrue(html.contains("function extractCodeLineFromSection"))
        XCTAssertTrue(html.contains("function isExtractableCodeMarkdown"))
        XCTAssertTrue(html.contains("function shouldDeleteEmptyCodeLine"))
        XCTAssertTrue(html.contains("function deleteEmptyCodeLine"))
        XCTAssertTrue(html.contains("formatting: \"delete-empty-code-line\""))
        XCTAssertTrue(html.contains("function parseImage"))
        XCTAssertTrue(html.contains("function renderImageBlockContent"))
        XCTAssertTrue(html.contains("function safeImageURL"))
        XCTAssertTrue(html.contains("data-image-lightbox"))
        XCTAssertTrue(html.contains("function openImageLightbox"))
        XCTAssertTrue(html.contains("function zoomImageLightbox"))
        XCTAssertTrue(html.contains("function resetImageLightboxZoom"))
        XCTAssertTrue(html.contains("function installImageInteractions"))
        XCTAssertTrue(html.contains("function unlockCodeSection"))
        XCTAssertTrue(html.contains("function unwrapCodeBlock"))
        XCTAssertTrue(html.contains("unwrapCodeBlock: true"))
        XCTAssertTrue(html.contains("documentChanged: \"extract-code-line\""))
        XCTAssertTrue(html.contains("formatting: \"unwrap-code-block\""))
        XCTAssertTrue(html.contains("if (inFence && !isFence(source))"))
        XCTAssertTrue(html.contains("function inlineMarkdownHTML"))
        XCTAssertTrue(html.contains("shouldParseTypedSource"))
        XCTAssertTrue(html.contains("function undo()"))
        XCTAssertTrue(html.contains("function redo()"))
        XCTAssertTrue(html.contains("restoreHistorySnapshot"))
        XCTAssertTrue(html.contains("function appendBlockAtEnd"))
        XCTAssertTrue(html.contains("function shouldAppendFromDocumentKeydown"))
        XCTAssertTrue(html.contains("function isTailAppendClick"))
        XCTAssertTrue(html.contains("append: \"tail\""))
        XCTAssertTrue(html.contains("function nextOrderedListMarker"))
        XCTAssertTrue(html.contains("Number(number) + 1"))
        XCTAssertTrue(html.contains("function shouldExitEmptyContinuationBlock"))
        XCTAssertTrue(html.contains("function shouldPromoteBlankTypedText"))
        XCTAssertTrue(html.contains("editor-block-empty-document"))
        XCTAssertTrue(html.contains("function installBlankDocumentClickTarget"))
        XCTAssertTrue(html.contains(".editor-block-empty-document {"))
        XCTAssertTrue(html.contains("min-height: calc(100vh - 124px);"))
        XCTAssertTrue(html.contains("margin: 0.18em 0 0.18em 1.08em;"))
        XCTAssertTrue(html.contains("left: -0.82em;"))
        XCTAssertTrue(html.contains(".editor-block-paragraph:has(+ .editor-block-unordered-list)"))
        XCTAssertTrue(html.contains(".editor-block-paragraph:has(+ .editor-block-ordered-list)"))
        XCTAssertTrue(html.contains(".editor-block-paragraph:has(+ .editor-block-blank + .editor-block-unordered-list)"))
        XCTAssertTrue(html.contains(".editor-block-paragraph:has(+ .editor-block-blank + .editor-block-ordered-list)"))
        XCTAssertTrue(html.contains("margin-bottom: 0.18em;"))
        XCTAssertFalse(html.contains("margin-top: -0.75em;"))
        XCTAssertTrue(html.contains("data-copy-document"))
        XCTAssertTrue(html.contains("title=\"Click to copy\""))
        XCTAssertTrue(html.contains("aria-label=\"Zoom in\""))
        XCTAssertTrue(html.contains("aria-label=\"Zoom out\""))
        XCTAssertTrue(html.contains("aria-label=\"Reset image zoom\""))
        XCTAssertTrue(html.contains("aria-label=\"Close image preview\""))
        XCTAssertTrue(html.contains("const copyIconSVG"))
        XCTAssertTrue(html.contains("const copiedIconSVG"))
        XCTAssertTrue(html.contains("const zoomIconSVG"))
        XCTAssertTrue(html.contains("copyButton.innerHTML = copyIconSVG"))
        XCTAssertTrue(html.contains("button.setAttribute(\"title\", \"Click to copy\")"))
        XCTAssertFalse(html.contains(">Click to Copy<"))
        XCTAssertFalse(html.contains(".editor-block-code-start:hover .code-copy-button"))
        XCTAssertTrue(html.contains("function installCopyControls"))
        XCTAssertTrue(html.contains("function requestMarkdownCopy"))
        XCTAssertTrue(html.contains("function codeSectionMarkdown"))
        XCTAssertTrue(html.contains("copyRequested"))
        XCTAssertTrue(html.contains("copyMarkdown"))
        XCTAssertTrue(html.contains("data-formatting-menu"))
        XCTAssertTrue(html.contains("function applyFormatting"))
        XCTAssertTrue(html.contains("function toggleInlineWrapper"))
        XCTAssertTrue(html.contains("data-format=\"code\""))
        XCTAssertTrue(html.contains("data-format=\"code-block\""))
        XCTAssertTrue(html.contains("aria-label=\"Code block\""))
        XCTAssertTrue(html.contains("data-format=\"link\""))
        XCTAssertTrue(html.contains("format-code"))
        XCTAssertTrue(html.contains("format-link"))
        XCTAssertTrue(html.contains("selectURLPlaceholder"))
        XCTAssertTrue(html.contains("function applyCodeBlockFormatting"))
        XCTAssertTrue(html.contains("function codeBlockFormatterSource"))
        XCTAssertTrue(html.contains("malformedOpening"))
        XCTAssertTrue(html.contains("\"```\" + language"))
        XCTAssertTrue(html.contains("&lt;mark&gt;([\\s\\S]*?)&lt;\\/mark&gt;"))
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

    func testIncludesRenderedTableSupport() {
        let html = MarkdownEditorHTML.document(
            markdown: "| Feature | Native | WebView |\n|---|---:|---:|\n| Text selection | TBD | TBD |",
            title: "Doc"
        )

        XCTAssertTrue(html.contains(".editor-table"))
        XCTAssertTrue(html.contains("function parseTableRow"))
        XCTAssertTrue(html.contains("function renderTableGroup"))
        XCTAssertTrue(html.contains("\"table-header\""))
        XCTAssertTrue(html.contains("\"table-separator\""))
        XCTAssertTrue(html.contains("updateTableCell"))
    }

    func testIncludesRenderedImageAndZoomSupport() {
        let html = MarkdownEditorHTML.document(markdown: #"![Diagram](diagram.png "System diagram")"#, title: "Doc")

        XCTAssertTrue(html.contains("\"image\""))
        XCTAssertTrue(html.contains("parseImageSource"))
        XCTAssertTrue(html.contains("parseImageTarget"))
        XCTAssertTrue(html.contains("editor-block-image"))
        XCTAssertTrue(html.contains("editor-image-frame"))
        XCTAssertTrue(html.contains("data-image-preview"))
        XCTAssertTrue(html.contains("data-open-image"))
        XCTAssertTrue(html.contains("Open image full screen"))
        XCTAssertTrue(html.contains("Image unavailable"))
        XCTAssertTrue(html.contains("translate(${imageLightboxState.x}px, ${imageLightboxState.y}px) scale(${imageLightboxState.scale})"))
    }

    func testImageURLsAreConstrainedInGeneratedEditorScript() {
        let html = MarkdownEditorHTML.document(markdown: "![Bad](javascript:alert(1))", title: "Doc")

        XCTAssertTrue(html.contains("normalized === \"http\" || normalized === \"https\" || normalized === \"file\""))
        XCTAssertTrue(html.contains("normalized === \"data\" && /^data:image\\/"))
        XCTAssertTrue(html.contains("url.startsWith(\"//\")"))
        XCTAssertTrue(html.contains("safeImageURL(block.destination)"))
        XCTAssertTrue(html.contains("function imageFallbackText"))
    }
}
