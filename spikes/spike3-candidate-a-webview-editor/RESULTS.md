# Spike 3 Results: Candidate A WebView Editor

Date: 2026-06-11

## Question

Can the Candidate A path use a WebView-hosted live-preview editor while keeping Markdown serialization app-owned?

## Prototype

This spike adds a dependency-free static prototype under `spikes/spike3-candidate-a-webview-editor`.

Files:

- `web/editor.html` - local prototype page.
- `web/editor.css` - light editor styling aligned with the app palette.
- `web/editor-core.mjs` - pure model and shortcut routing logic.
- `web/editor-ui.mjs` - contenteditable browser UI that renders and updates the model.
- `tests/editor-core.test.mjs` - Node built-in tests for model behavior.

Validation command:

```sh
node --test spikes/spike3-candidate-a-webview-editor/tests/*.test.mjs
```

Latest result:

- Passed.
- 5 tests.
- Covered no-edit round-trip, marker-preserving visible edits, marker unlock, intentional presentation-type change from unlocked source, and native shortcut routing classification.

## Findings

The core Candidate A shape is viable enough to prototype further.

Evidence:

- The editor model can parse common block-like lines into visible text plus Markdown marker state.
- Ordinary visible-text edits preserve Markdown markers for headings, list items, quotes, fences, and code content.
- Pressing Left Arrow at caret offset `0` can be modeled as an intentional marker-unlock transition.
- Once unlocked, changing raw source can intentionally change presentation type.
- `Cmd+Up`, `Cmd+Down`, `Cmd+Left`, `Cmd+Right`, `Cmd+O`, `Cmd+F`, `Cmd+/`, and `Cmd+R` can be classified for native app routing instead of being consumed as editor text behavior.
- `Cmd+S` can be classified separately as an editing save command.

What this does not prove:

- Native `WKWebView` bridge implementation.
- IME correctness.
- Browser/WebView undo and redo behavior.
- Paste behavior.
- Selection persistence across model re-render.
- Accessibility quality of contenteditable blocks.
- Large-file performance.
- Conflict handling for unsaved edits when files change on disk.

Automated browser screenshot was not captured in this environment because Playwright is not installed. The prototype remains manually inspectable with:

```sh
python3 -m http.server 8765 --directory spikes/spike3-candidate-a-webview-editor/web
open http://127.0.0.1:8765/editor.html
```

## Recommendation

Proceed to a native macOS Candidate A prototype, still outside production reader behavior.

Recommended next implementation:

- Add a small `WKWebView` editor spike app or app-internal debug view.
- Load HTML/CSS/JS similar to this prototype.
- Bridge editor events to Swift.
- Keep Swift as the authoritative Markdown serializer.
- Treat DOM text and selection as interaction state only.
- Test shortcut routing with the existing app-level keyboard monitor.
- Add focused manual checks for IME, paste, undo/redo, selection, and accessibility.

Do not ship editing in the main app yet. Candidate A is promising, but the high-risk native-input and WebView-bridge questions remain open.

## Production Gate

Before production editing:

- Golden tests for whole-document round-trip across common Markdown fixtures.
- WebView bridge tests for event payload encoding.
- Manual and automated smoke for editing heading/list/quote/code content.
- IME and paste smoke.
- Undo/redo smoke.
- Shortcut smoke for `Cmd+O`, `Cmd+F`, `Cmd+Up`, `Cmd+Down`, `Cmd+Left`, `Cmd+Right`, and `Cmd+S`.
- Large-file edit profile.
- Unsaved edit conflict policy for file watcher updates.
