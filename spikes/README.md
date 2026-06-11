# Technical Spikes

Spikes answer risky technical questions before the product architecture locks in.

## Spike Order

1. `spike1-rendering-engine` - Should preview rendering be native SwiftUI/AppKit or WebView-backed?
2. `spike2-editing-update-mode` - Can a Markdown line model preserve presentation during ordinary edits?
3. `spike3-candidate-a-webview-editor` - Can Candidate A's live-preview editor behavior work in a browser/WebView-style surface?
4. `spike4-native-webview-editor` - Can Candidate A run inside a native macOS `WKWebView` host with Swift bridge validation?

## Spike Rules

- Keep each spike narrow.
- Define pass/fail criteria before building.
- Capture measurements and qualitative observations.
- Write results down before promoting any code.
- Do not let spike code silently become production code.
