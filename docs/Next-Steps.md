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
- Focused accessibility spot check.

## Future Candidates

These are not active backlog items for the completed reader-MVP checklist.

### Production Editing / Update Mode

Use the Spike 2 recommendation:

- prototype a WebView-backed live-preview editor first;
- keep Markdown serialization in an app-owned Swift line/block model;
- do not ship editing until the production gates in `spikes/spike2-editing-update-mode/RESULTS.md` are proven.

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
