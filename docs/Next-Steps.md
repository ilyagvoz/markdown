# Next Steps

Last updated: 2026-06-11

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

Add signing, notarization, and release packaging once the app is ready to distribute beyond local install.

## Gates For Future Features

Run before marking future work complete:

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

Run for editing-spike changes:

```sh
swift test --package-path spikes/spike2-editing-update-mode
node --test spikes/spike3-candidate-a-webview-editor/tests/*.test.mjs
spikes/spike4-native-webview-editor/scripts/smoke-native-editor.sh
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
