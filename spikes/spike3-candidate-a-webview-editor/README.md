# Spike 3: Candidate A WebView Editor

Status: in progress.

## Goal

Prototype the Candidate A path from Spike 2: a WebView-backed live-preview editor that preserves the current reading style while keeping Markdown serialization app-owned.

## Questions

- Can ordinary visible-text edits preserve Markdown presentation markers?
- Can marker unlock be modeled as an intentional transition instead of an accidental edit?
- Can the editor keep app-level shortcuts, such as `Cmd+Up`, `Cmd+Down`, `Cmd+Left`, and `Cmd+Right`, available to the native app?
- Can the WebView layer act as interaction state while Markdown serialization remains owned by the app model?

## Prototype Shape

- `web/editor.html` is a static prototype page that can be loaded in a browser or WebView.
- `web/editor-core.mjs` contains the pure editor model and shortcut classification logic.
- `web/editor-ui.mjs` renders the model into contenteditable blocks and updates model visible text from user input.
- `tests/editor-core.test.mjs` validates serialization, marker-preserving edits, marker unlock, and shortcut routing assumptions.

## Validation

Run:

```sh
node --test spikes/spike3-candidate-a-webview-editor/tests/*.test.mjs
```

Manual prototype:

```sh
open spikes/spike3-candidate-a-webview-editor/web/editor.html
```

## Non-Goals

- No production app integration.
- No editor framework choice yet.
- No persistent saves.
- No native WebView bridge implementation yet.
- No claim that IME, paste, undo/redo, or accessibility are solved.
