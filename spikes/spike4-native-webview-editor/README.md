# Spike 4: Native WebView Editor

Question: can Candidate A work inside a native macOS `WKWebView` host, preserving rendered Markdown presentation during ordinary edits while allowing intentional type changes after unlock?

## Scope

- Host the Candidate A live-preview editing model in AppKit + `WKWebView`.
- Route editor state from JavaScript to Swift through a small WebKit bridge.
- Keep Markdown serialization app-owned and observable from Swift.
- Add an automated native smoke path that loads WebKit, performs edits, checks serialization, and exits.

Out of scope:

- Production save/writeback.
- IME correctness.
- Full undo/redo behavior.
- Paste normalization.
- Accessibility audit.
- Large-file editing measurements.

## Run

```sh
spikes/spike4-native-webview-editor/scripts/smoke-native-editor.sh
```

Manual launch:

```sh
swift run --package-path spikes/spike4-native-webview-editor NativeWebViewEditorSpike
```

## Files

- `Sources/NativeWebViewEditorSpike/main.swift` - AppKit host, WebView bridge, source/status panel, and native smoke mode.
- `Sources/NativeWebViewEditorSpike/Resources/editor.html` - editor WebView shell.
- `Sources/NativeWebViewEditorSpike/Resources/editor-bundle.js` - self-contained live-preview editor script for native WebKit.
- `Sources/NativeWebViewEditorSpikeSupport/EditorBridgeMessage.swift` - testable Swift bridge message parser/status formatter.
- `Tests/NativeWebViewEditorSpikeSupportTests/EditorBridgeMessageTests.swift` - bridge contract tests.

