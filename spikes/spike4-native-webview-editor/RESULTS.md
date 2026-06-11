# Spike 4 Results: Native WebView Editor

Date: 2026-06-11

## Result

Candidate A works at native-spike level.

The spike proves a macOS `WKWebView` can host the live-preview editor interaction model:

- ordinary visible-text edits preserve Markdown presentation markers;
- unlocking a line exposes raw Markdown source for intentional type changes;
- pressing Return or leaving an unlocked line commits the raw source back into the newly parsed rendered type;
- JavaScript editor state can be serialized and sent to Swift through a small WebKit bridge;
- a native smoke mode can load the WebView, mutate the document, verify serialization, and terminate automatically.

## Validation

Passed:

```sh
spikes/spike4-native-webview-editor/scripts/smoke-native-editor.sh
```

The script runs:

- `swift test --package-path spikes/spike4-native-webview-editor`
- `swift build --package-path spikes/spike4-native-webview-editor`
- `.build/debug/NativeWebViewEditorSpike --smoke`

Latest smoke result:

```text
SMOKE_OK native WebView editor preserved style until explicit unlock
```

## Observations

- The Swift bridge should stay small, typed, and unit-tested. `EditorBridgeMessageParser` is a good shape for production support code.
- Native WebKit could load bundled HTML/CSS reliably from SwiftPM resources.
- Local ES module imports from the SwiftPM resource bundle did not initialize reliably in smoke mode. The native spike uses a self-contained classic script instead.
- The current JavaScript model remains useful for interaction behavior, but production should keep canonical Markdown state in Swift and treat DOM state as editable presentation state.
- The native smoke test is valuable because it catches WebKit resource-loading failures that pure unit tests cannot see.
- Raw-marker editing needs an explicit commit moment. A user-observed issue showed that changing `- Item` to `> Item` updated serialized Markdown but stayed visually raw. The spike now commits unlocked source on Return or blur and smoke-tests list-to-quote re-rendering.

## Recommendation

Proceed toward production editing with this shape:

1. Put the canonical Markdown line/block model in Swift app-support/core code.
2. Use a `WKWebView` editing surface for live-preview interaction.
3. Keep a narrow bridge contract for document changes, unlock events, save requests, and native shortcut routing.
4. Add native smoke coverage before merging editing into the production app.

Do not ship editing yet. Production gates still need to prove IME/input correctness, undo/redo, selection, paste behavior, save/writeback safety, file-change conflict behavior, accessibility, and large-file performance.
