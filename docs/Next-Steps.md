# Next Steps

Last updated: 2026-06-13

All planned reader-MVP items from the previous backlog are complete. Completed capabilities and lessons live in `docs/Progress.md`; latest test/profile/screenshot results live in `docs/Validation.md`.

## Current State

Complete:

- Workspace-wide search.
- Sidebar keyboard navigation.
- Selected-file deletion/rename handling.
- Visual polish screenshot pass.
- App icon and bundle metadata.
- Editing/update-mode spike and recommendation.
- Native WebView editing spike and recommendation.
- Production live-preview editing implementation.
- Focused accessibility spot check.
- Autosave, folder pruning, new-file creation, file rename, selection formatting, and split fast-smoke/UI-E2E coverage.

## Future Candidates

These are not active backlog items for the completed reader-MVP checklist.

### Live Preview Editing Hardening

The app implements the first production live-preview editor pass.

Remaining hardening candidates:

- improve inline editing caret preservation when a focused line reveals raw inline Markdown;
- add paste normalization tests;
- add IME/input-method validation;
- add large-file editing profile and screenshot coverage;
- decide how to handle unsaved local edits when the same file changes externally.

### Broader Accessibility Pass

Run a fuller hands-on VoiceOver and keyboard accessibility pass before external distribution.

### Distribution Hardening

Add Developer ID signing, notarization, and universal or clearly split architecture release packaging once the app is ready to distribute beyond the early 0.1 GitHub release.

## Gates For Future Features

Use `docs/Test-Coverage.md` as the canonical test-selection guide. Run the smallest gate that covers the changed surface during iteration, and reserve the full installed-app E2E battery for shipping, broad progress records, or cross-cutting app wiring changes.

Update the relevant docs in the same change:

- `docs/Progress.md` for completed capabilities and lessons.
- `docs/Validation.md` for latest test/profile/screenshot results.
- `docs/Validation-History.md` for older smoke transcripts, crash notes, or detailed investigation records that should not crowd the latest-status view.
- `docs/Test-Coverage.md` for user-focused coverage.
- `docs/Architecture-Decisions.md` for durable architecture choices.

## Explicitly Out Of Scope

- Scroll-position restoration.
- Obsidian-style wiki links, backlinks, graph views, plugins, sync, or heavy knowledge-management features.
- Persistent indexing or a database until measurement proves it is needed.
