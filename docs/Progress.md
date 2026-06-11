# Progress

Last updated: 2026-06-11

This document preserves completed product progress and implementation lessons so `docs/Next-Steps.md` can stay focused on future planning.

## Shipped MVP Foundation

The first polished MVP slice is implemented under `apps/macos/Markdown`.

Complete capabilities:

- Native SwiftUI macOS app shell.
- Light-only visual design for MVP.
- WebView-backed Markdown preview using app-owned HTML/CSS.
- Common Markdown rendering through a replaceable adapter.
- Unified `Cmd+O` flow for opening files and folders.
- Collapsible sidebar tree for folders and Markdown files.
- Recent files/folders and Open Recent menu.
- Last-opened workspace/file restoration.
- Selected-file live refresh when the Markdown file changes on disk.
- Folder watching for added/deleted Markdown files in opened folders.
- Current-document search with `Cmd+F`.
- Workspace-wide search across opened folders, without a persistent index.
- Right-side document outline with heading and landmark jumps.
- Left and right pane toggles with `Cmd+Left Arrow` and `Cmd+Right Arrow`.
- Pane size and visibility persistence for the left sidebar and right outline.
- App-level command-arrow routing so `Cmd+Up` and `Cmd+Down` continue to change documents when focus is in preview/search/outline.
- `Cmd+R` reveal in Finder.
- Help menu keyboard shortcut reference.
- Lightweight CPU/RSS readout in the status area.
- Release build, install, profile, and UI smoke scripts.

## Architecture Decisions In Force

- Use a native macOS app for MVP.
- Render Markdown in preview mode by default.
- Support common Markdown only.
- Use a small repo shape: `apps`, `docs`, `spikes`, and future packages only when justified.
- Use WebView-backed preview rendering for MVP, behind a renderer adapter.
- Keep the MVP light-mode only.

Durable decisions live in `docs/Architecture-Decisions.md`.

## Validation Baseline

Current verified gates:

- `./scripts/test-macos.sh` passes with 18 tests.
- `./scripts/build-macos-app.sh` builds `artifacts/Markdown.app`.
- `./scripts/install-macos-app.sh` installs `/Applications/Markdown.app`.
- `./scripts/smoke-macos-ui.sh` passes against the installed app.
- `./scripts/profile-macos.sh spikes/spike1-rendering-engine/fixtures` shows settled idle CPU near 0% and RSS around 92-95 MB in release builds.

Current UI smoke coverage includes:

- single-file open
- folder open
- unified open panel shortcut
- current-document search
- workspace-wide search
- outline jumps
- pane visibility toggles
- document navigation shortcuts
- reveal in Finder
- watched-folder add/delete
- crash-report checks

See `docs/Validation.md` and `docs/Test-Coverage.md` for the latest details.

## Implementation Lessons

WebView preview is the right MVP path. Spike 1 showed it gives much better large-document behavior and preserves semantic Markdown layout more cleanly than the first native attributed-text prototype. Keep parser/rendering behind an adapter so the choice remains reversible if later accessibility, selection, memory, or editing evidence changes the tradeoff.

Use app-owned preview styling. The reading experience depends on local CSS that controls font stack, line height, content width, code blocks, tables, links, and the light palette.

Do not add heavy knowledge-management behavior by accident. Search and outline are document/workspace navigation aids, not a reason to add wiki links, backlinks, graph views, plugins, sync, or a database.

Treat WebView bridge code as crash-sensitive. The search/outline crash came from using `NSJSONSerialization` for a top-level JavaScript string. Keep JavaScript generation small, tested, and isolated in support code.

Treat filesystem watchers as actor-sensitive. The live-refresh crash came from dispatch-source callbacks crossing actor isolation unexpectedly. Keep watcher callbacks on the queue/actor their state expects, and cover user workflows with crash-report smoke checks.

User-facing automation matters. The smoke suite caught and now guards the important flows: opening, search, outline, shortcuts, folder watching, and crash reports. Add pure unit tests for deterministic logic and UI smoke for SwiftUI/AppKit/WebKit interaction boundaries.

Pane dragging itself should remain manual QA for now. Synthetic macOS drag-coordinate tests were unreliable. The saved pane layout state is unit-tested, and pane visibility is covered by UI smoke.

Visual polish is product work, not garnish. The app should remain light, quiet, readable, and joyful. Avoid heavy visible divider lines; invisible resize hit targets fit the current design better.

## Deferred But Important

- Production editing/update mode.
- Fuller first-responder sidebar keyboard navigation for plain arrows, folder selection, `Return`, and `Space`.
- Selected-file deletion/rename UX.
- Accessibility pass, especially VoiceOver labels and focus behavior.
- App icon and final bundle identity.
- Signed/notarized distribution.
- Large-file screenshot/performance smoke.
