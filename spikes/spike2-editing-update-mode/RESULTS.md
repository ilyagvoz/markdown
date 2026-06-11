# Spike 2 Results: Editing / Update Mode

Date: 2026-06-11

## Question

Can Markdown add Obsidian-like live-preview editing while preserving the current preview-first appearance and avoiding Markdown source corruption?

## Prototype

This spike adds a small Swift package under `spikes/spike2-editing-update-mode`.

The prototype models Markdown as editable lines with:

- a presentation type, such as heading, list item, quote, fenced code, code content, paragraph, or blank;
- visible text that can be edited without showing the Markdown marker;
- marker prefix/suffix data used to serialize edits back to Markdown;
- an unlocked source representation for intentional type changes.

Validation command:

```sh
swift test --package-path spikes/spike2-editing-update-mode
```

Latest result:

- Passed.
- 7 tests.
- Covered no-edit round-trip, heading edits, ordered/unordered list edits, quote edits, fenced-code language edits, code-content edits, and marker unlock behavior.

## Candidate A: WebView Editor With App-Owned Serialization

Use a WebView-hosted editing layer for presentation and interaction, but keep Markdown serialization in app-owned Swift model code.

Assessment:

- Best match for the current WebView preview renderer and local CSS.
- Most likely to preserve the app's current typography, spacing, outline anchors, and visual joy.
- Lets production reuse current preview rendering concepts instead of building a second native renderer.
- Requires careful event routing so app-level shortcuts keep winning over WebView defaults.
- Requires explicit testing for IME, paste, undo/redo, focus, selection, and large files.
- Should not let DOM HTML become the saved source of truth.

The line-model prototype supports this path because it proves ordinary visible-text edits can preserve Markdown markers and serialize back predictably for common block shapes.

## Candidate B: Native `NSTextView` With Attributed Markdown Model

Use `NSTextView` or a SwiftUI wrapper around it, backed by a Markdown-aware attributed text model.

Assessment:

- Best native input story for IME, selection, undo/redo, accessibility, services, and spellchecking.
- Strongest fit if WebView editing fails platform expectations.
- Much higher rendering burden: headings, code blocks, tables, images, diagrams, and future outline anchors would require a parallel native layout/rendering implementation.
- Higher risk of degrading the current reading experience because preview and edit display would diverge.

The prototype does not rule this out, but it suggests the native path should remain the fallback rather than the first production attempt.

## Recommendation

Prototype production editing with Candidate A first: a WebView-backed live-preview editor using app-owned Markdown serialization.

Recommended production shape:

- Keep the existing preview renderer as the read mode.
- Add an edit mode only after a focused editor prototype proves input behavior.
- Represent editable Markdown as an app-owned block/line model.
- Treat WebView DOM/editor state as interaction state, not saved source truth.
- Serialize Markdown only from the app-owned model.
- Preserve presentation style for ordinary text edits by default.
- Expose raw Markdown markers only through an intentional unlock action at the beginning of the line.
- Save with `Cmd+S` only after round-trip tests are broad enough.

## Production Gate

Do not ship editing until all of these are proven:

- Common Markdown round-trips without source corruption.
- Golden tests cover headings, paragraphs, emphasis-bearing lines, ordered/unordered lists, blockquotes, fenced code, tables, images, and mixed documents.
- Ordinary edits preserve current block presentation.
- Marker unlock supports changing heading/list/quote/code markers intentionally.
- Undo/redo behaves predictably.
- IME and paste behavior are acceptable.
- `Cmd+O`, `Cmd+F`, `Cmd+Up`, `Cmd+Down`, `Cmd+Left Arrow`, `Cmd+Right Arrow`, and `Cmd+S` behave correctly while editing.
- Large files remain responsive.
- File-change awareness has a deliberate conflict policy for unsaved edits.

## Open Risks

- DOM selection and Swift model synchronization may be fragile.
- WebView editor accessibility may not match native text editing.
- Markdown tables and images need block-aware behavior beyond this line-model prototype.
- Collaborative or multi-cursor editing remains out of scope.
- Unsaved local edits introduce conflict states that the current reader does not have.
