# Next Steps

Last updated: 2026-06-11

This is the forward-looking planning backlog. Completed work and implementation lessons live in `docs/Progress.md`; latest test/profile results live in `docs/Validation.md`.

## Current Planning Goal

Decide the next product stage now that the preview-first MVP foundation is stable.

Recommended next stage: make Markdown useful for daily reading across real local folders, without starting the full editing project yet.

## Stage Candidates

### 1. Editing / Update Mode Spike

Goal: decide whether live-preview editing is feasible without corrupting Markdown or degrading the reading experience.

Product behavior to investigate:

- Editing an existing line should preserve its current presentation style by default.
- If the cursor is inside code, heading, list item, quote, or paragraph content, ordinary text edits should keep that presentation mode.
- Changing a line's presentation type should be intentional.
- Moving to the beginning of the line and pressing `Left Arrow` should expose/unlock Markdown markers so the user can change `#`, list markers, quote markers, fenced code markers, or remove them.
- `Cmd+S` should save once editing exists.

Spike options:

- WebView editor using contenteditable or ProseMirror-like document behavior while keeping app-owned Markdown serialization.
- Native `NSTextView`/SwiftUI text editor with attributed presentation and a Markdown-aware line model.

Evaluate:

- caret behavior
- IME/input correctness
- undo/redo
- selection
- keyboard shortcuts
- paste behavior
- Markdown serialization
- performance on large files
- Common Markdown round-trip safety

Validation:

- Golden round-trip tests before production editing ships.
- Explicit recommendation before implementation.

### 2. Accessibility / VoiceOver Spot Check

Goal: confirm the reader MVP is navigable and understandable with macOS accessibility tooling.

Scope:

- Spot check the window, left sidebar rows, preview controls, search panel, and outline panel.
- Verify folders and Markdown files are distinguishable.
- Verify expanded/collapsed folder state is understandable.
- Verify the supported keyboard path does not trap focus.
- Keep this as a focused spot check, not a full formal accessibility audit.

Validation:

- Record findings in `docs/Validation.md`.
- Fix critical issues found during the spot check.

## Suggested Order

1. Editing/update-mode spike.
2. Focused accessibility/VoiceOver spot check.

Reasoning: workspace-wide search, sidebar keyboard navigation, selected-file churn handling, visual screenshot review, and app identity are complete. The remaining product-planning work is the editing spike plus a focused hands-on accessibility check.

## Gates For Any Next Feature

Run before marking work complete:

```sh
./scripts/test-macos.sh
./scripts/build-macos-app.sh
./scripts/install-macos-app.sh
./scripts/smoke-macos-ui.sh
```

Run for performance-sensitive changes:

```sh
./scripts/profile-macos.sh spikes/spike1-rendering-engine/fixtures
```

Update the relevant docs in the same change:

- `docs/Progress.md` for completed capabilities and lessons.
- `docs/Validation.md` for latest test/profile/screenshot results.
- `docs/Test-Coverage.md` for user-focused coverage.
- `docs/Architecture-Decisions.md` for durable architecture choices.

## Explicitly Out Of Scope

- Scroll-position restoration.
- Obsidian-style wiki links, backlinks, graph views, plugins, sync, or heavy knowledge-management features.
- Persistent indexing or a database until measurement proves it is needed.
