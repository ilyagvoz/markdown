# Next Steps

Last updated: 2026-06-11

This is the forward-looking planning backlog. Completed work and implementation lessons live in `docs/Progress.md`; latest test/profile results live in `docs/Validation.md`.

## Current Planning Goal

Decide the next product stage now that the preview-first MVP foundation is stable.

Recommended next stage: make Markdown useful for daily reading across real local folders, without starting the full editing project yet.

## Stage Candidates

### 1. File Deletion And Rename UX

Goal: handle real-world file churn gracefully.

Scope:

- If the selected file is deleted, show a quiet missing-file state and select a sensible nearby file when possible.
- If the selected file is renamed, refresh the tree and avoid showing stale content.
- Preserve expanded folders during rebuilds.
- Avoid surprising automatic jumps when the user's reading context is still available.

Validation:

- Unit-test workspace rebuild behavior around selected-file preservation and removal.
- UI smoke: delete the selected file in an opened folder and verify no crash report appears.

### 2. Visual Polish Pass

Goal: keep the app clean, readable, and pleasant for everyday use before adding larger features.

Scope:

- Screenshot the current three-pane app at default and small window sizes.
- Review sidebar density, typography, header treatment, empty states, search UI, outline panel, status readout, and pane resizing.
- Confirm light-only styling remains consistent across app chrome and WebView preview.
- Keep resize dividers invisible; avoid heavy pane boundary lines.
- Include a focused accessibility/VoiceOver spot check for sidebar rows and main navigation.
- Iterate until the app feels calm, native, and joyful to launch.

Validation:

- Save screenshots under `artifacts/screenshots`.
- Record assessment in `docs/Validation.md`.

### 3. App Identity

Goal: make the installed app feel real.

Scope:

- Add a proper app icon.
- Refine bundle metadata.
- Keep local install flow simple through `./scripts/install-macos-app.sh`.
- Defer signing/notarization until the app is closer to distribution.

Validation:

- Build and install the app.
- Confirm the app icon appears in Finder, Dock, App Switcher, and Launchpad/Spotlight where available.

### 4. Editing / Update Mode Spike

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

## Suggested Order

1. File deletion/rename UX.
2. Visual polish pass.
3. App identity.
4. Editing/update-mode spike.

Reasoning: workspace-wide search and sidebar keyboard navigation are complete. File churn is the next reader-usefulness gap while keeping the stable preview-first foundation intact. Editing is valuable but risky enough to keep behind a spike until the reader experience is stronger.

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
