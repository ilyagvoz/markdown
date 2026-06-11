# Spike 1 Results

Status: passed.

## Recommendation

Use a WebView-backed Markdown preview for MVP.

The production app should keep file/folder navigation native, but render Markdown through a renderer adapter that generates semantic HTML and loads it into `WKWebView` with local app-owned CSS. Keep JavaScript disabled unless a future feature explicitly requires it.

Reasoning:

- WebView preserves common Markdown block layout naturally through HTML/CSS.
- `swift-markdown` already provides semantic HTML output for headings, lists, code blocks, blockquotes, images, and tables.
- A native attributed-text renderer is fast for small documents, but it needs custom block layout for real Markdown fidelity.
- The native prototype was much slower on a 132 KB synthetic long document once it performed block-aware rendering.
- WebView leaves more implementation time for the native file/folder experience, which is the actual product differentiator.

## Measurements

Environment:

- Swift 6.x
- Xcode 26.5
- Command: `swift run -c release rendering-spike`
- Runs per renderer/fixture: 5
- Large synthetic fixture: 132,498 bytes, about 21,000 words

| Fixture | Renderer | Median ms | Min ms | Max ms | RSS Delta MB |
|---|---:|---:|---:|---:|---:|
| basic.md | native-attributed-text | 0.40 | 0.25 | 9.94 | 28.30 |
| basic.md | webview-html | 1.55 | 1.13 | 113.20 | 23.62 |
| code.md | native-attributed-text | 0.20 | 0.18 | 0.84 | 0.03 |
| code.md | webview-html | 1.00 | 0.85 | 2.00 | 0.02 |
| images.md | native-attributed-text | 0.18 | 0.16 | 0.45 | 0.03 |
| images.md | webview-html | 0.94 | 0.75 | 1.44 | 0.03 |
| large.md | native-attributed-text | 0.61 | 0.58 | 0.86 | 0.09 |
| large.md | webview-html | 1.26 | 0.99 | 2.30 | 0.06 |
| lists.md | native-attributed-text | 0.35 | 0.34 | 0.50 | 0.02 |
| lists.md | webview-html | 1.18 | 0.95 | 1.33 | 0.03 |
| quotes.md | native-attributed-text | 0.27 | 0.22 | 1.23 | 0.38 |
| quotes.md | webview-html | 0.75 | 0.72 | 1.06 | 0.02 |
| tables.md | native-attributed-text | 0.22 | 0.17 | 0.41 | 0.03 |
| tables.md | webview-html | 0.97 | 0.87 | 1.44 | 0.16 |
| large-synthetic.md | native-attributed-text | 661.14 | 658.16 | 666.94 | 9.77 |
| large-synthetic.md | webview-html | 40.77 | 39.67 | 42.26 | 0.62 |

## Native Prototype Notes

- First attempt using Foundation/AppKit Markdown attributed strings was not viable by itself: block structure was preserved as metadata, but the plain string collapsed headings, paragraphs, lists, and code blocks together.
- The measured native prototype therefore uses `swift-markdown` and a custom block-aware `NSAttributedString` builder.
- Small documents are extremely fast.
- Long-document behavior is poor in the current prototype.
- Native rendering would require custom work for tables, local images, code block backgrounds, nested list layout, selection behavior, and accessibility semantics.
- A production-quality native renderer may be possible, but it is a larger rendering project than this MVP needs.

## WebView Prototype Notes

- Uses `swift-markdown` to parse Markdown and `HTMLFormatter` to generate semantic HTML.
- Uses `WKWebView` to load local generated HTML with app-owned CSS.
- Small documents are slower than native attributed text but still comfortably below perceptible thresholds after WebView warmup.
- Large-document render time is much better than the native prototype.
- Tables come mostly for free through HTML.
- A follow-up visual check confirmed the WebView path looks materially better with app-owned CSS.
- Production should use light-only CSS for MVP and explicitly control fonts, spacing, readable width, tables, code blocks, and links.
- Production must handle local image base URLs, link interception, scroll position, and JavaScript-disabled configuration.

## Decision

ADR 005 is updated to accept WebView-backed preview rendering for MVP.
