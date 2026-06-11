# Spike Notes

## Running The Harness

```sh
cd spikes/spike1-rendering-engine
swift run -c release rendering-spike
```

## Prototype Scope

The harness compares display strategies through the same parser.

Both paths currently use `swift-markdown` from the Swift project:

- `native-attributed-text`: Markdown AST to a custom block-aware `NSAttributedString`, then `NSTextView` layout.
- `webview-html`: Markdown AST to semantic HTML through `HTMLFormatter`, then `WKWebView` load.

This keeps input semantics consistent while exposing the cost and ergonomics of native text layout versus WebKit display.

The package is currently pinned through SwiftPM resolution to the fetched `swift-markdown` and `swift-cmark` revisions in `Package.resolved`. Production work should revisit dependency pinning before release.
