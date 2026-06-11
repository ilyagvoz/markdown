# Spike 2: Editing / Update Mode

## Goal

Work out how to add Obsidian-like live-preview editing without corrupting Markdown source or losing the app's clean preview-first feel.

## Desired Behavior

- Editing an existing line preserves that line's presentation by default.
- A heading stays visually like a heading while its text is edited.
- A list item stays visually like a list item while its text is edited.
- A code block stays visually like code while code text is edited.
- Changing presentation type is intentional: move to the beginning of the line and press `Left Arrow` to expose/unlock the Markdown marker.
- Once unlocked, the user can change `#`, list markers, quote markers, fenced code markers, or remove them.

## Candidate A: WebView Editor

Use a WebView-hosted editor layer with contenteditable or a structured editor model.

Strengths:

- Closest to the current WebView-backed rendering architecture.
- Easiest path to preserve the same typography and CSS.
- Strong fit for line/block-level live-preview behavior.

Risks:

- Markdown round-tripping needs careful ownership.
- Native undo, selection, drag/drop, and input methods need testing.
- App-level shortcuts must continue to win over WebView defaults.

Validation needed:

- IME/text input.
- Undo/redo.
- Paste Markdown and rich text.
- Multi-cursor or multi-selection expectations, if any.
- Large-file performance.

## Candidate B: Native Text System

Use `NSTextView` with attributed presentation and a Markdown-aware line/block model.

Strengths:

- Best native text input, selection, accessibility, and undo/redo behavior.
- Easier to integrate with macOS services.
- Avoids deep WebView editing edge cases.

Risks:

- Much more work to match rendered Markdown fidelity.
- Tables, code blocks, images, and future diagrams become custom layout work.
- Harder to preserve the current preview joy without building a renderer twice.

Validation needed:

- Attributed rendering fidelity for common Markdown.
- Line marker reveal/hide behavior.
- Round-trip serialization.
- Performance on large documents.

## Early Recommendation

Prototype Candidate A first. It matches the accepted WebView renderer architecture and has the best chance of preserving the current app appearance. The production boundary should remain app-owned Markdown serialization: the editor may manage interaction, but the app must own what gets saved.

Candidate B remains the fallback if WebView editing fails native input expectations.

## Production Gate

Do not ship editing until the spike proves:

- Common Markdown round-trips without source corruption.
- Undo/redo behaves predictably.
- `Cmd+O`, `Cmd+F`, `Cmd+Up`, `Cmd+Down`, `Cmd+Left Arrow`, and `Cmd+Right Arrow` keep working while editing.
- Editing a large file remains responsive.
- File-change awareness has a clear conflict behavior for unsaved edits.
