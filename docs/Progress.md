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
- Selected-file rename/delete handling that avoids stale preview content and picks a nearby Markdown file when possible.
- Current-document search with `Cmd+F`.
- Workspace-wide search across opened folders, without a persistent index.
- Right-side document outline with heading and landmark jumps.
- Left and right pane toggles with `Cmd+Left Arrow` and `Cmd+Right Arrow`.
- Pane size and visibility persistence for the left sidebar and right outline.
- App-level command-arrow routing so `Cmd+Up` and `Cmd+Down` continue to change documents when focus is in preview/search/outline.
- Sidebar row keyboard navigation for folders and files with plain arrows, `Return`, and `Space`.
- `Cmd+R` reveal in Finder.
- Help menu keyboard shortcut reference.
- Lightweight CPU/RSS readout in the status area.
- Visual polish screenshot pass for default, small-window, and workspace-search states.
- App icon and Markdown document bundle metadata.
- Editing/update-mode spike with tested Markdown line-model prototype and recommendation.
- Candidate A WebView editor spike with tested marker-preserving browser model prototype.
- Native WebView editor spike with a Swift/AppKit host, WebKit bridge, and automated native smoke validation.
- Production live-preview editing with WebView-backed editable Markdown blocks, `Cmd+S` save, `Cmd+Z` / `Shift+Cmd+Z` undo/redo, marker replacement, new-line block creation, hidden block syntax in read mode, inline read-mode rendering, restored preview-like spacing, and smoke coverage for saved Markdown output.
- Folder-view Markdown file creation with `Cmd+N`, unique `Untitled.md` naming, automatic sidebar refresh, and selection of the new file.
- Debounced autosave after editing pauses, plus dirty-document flush before switching/opening files.
- Sidebar pruning that hides child folders without Markdown descendants.
- File rename from the File menu and file-row context menu, with a native rename prompt and safe extension handling.
- Selection-based editor formatting with a floating formatting toolbar, `Cmd+B` bold, `Cmd+I` italic, `Cmd+E` inline code, `Cmd+K` links, and inline HTML `<mark>` highlighting.
- Click-to-copy Markdown controls for the whole document and each fenced code section, backed by the native pasteboard.
- Focused accessibility spot check with explicit labels added for icon-only controls.
- Markdown preview hardening that renders raw HTML as text and only opens clicked `http` / `https` links externally.
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

- `./scripts/test-macos.sh` passes with 28 tests.
- `./scripts/build-macos-app.sh` builds `artifacts/Markdown.app`.
- `./scripts/install-macos-app.sh` installs `/Applications/Markdown.app`.
- Focused UI smoke scripts cover navigation, file actions, editing, and watcher behavior independently.
- `./scripts/smoke-macos-ui.sh` orchestrates the focused UI smoke scripts and passes against the installed app.
- `swift test --package-path spikes/spike2-editing-update-mode` passes with 7 tests.
- `node --test spikes/spike3-candidate-a-webview-editor/tests/*.test.mjs` passes with 5 tests.
- `spikes/spike4-native-webview-editor/scripts/smoke-native-editor.sh` passes with 4 Swift bridge tests plus native WebView smoke.
- `./scripts/profile-macos.sh spikes/spike1-rendering-engine/fixtures` shows settled idle CPU near 0% and RSS around 92-95 MB in release builds.

Current UI smoke coverage includes:

- single-file open
- folder open
- unified open panel shortcut
- current-document search
- workspace-wide search
- outline jumps
- pane visibility toggles
- plain-key sidebar navigation
- document navigation shortcuts
- reveal in Finder
- new Markdown file creation in an opened folder
- debounced autosave for typed edits
- selected-file rename
- watched-folder add/delete
- selected-file rename/delete and final-file deletion
- live-preview editing, saving, undo/redo, new bullet creation, ordered-list continuation, ordered-list exit, blank-line paragraph entry, marker replacement, bold/italic/code/link/highlight formatting, whole-document Markdown copy, and fenced-code-section Markdown copy
- crash-report checks

See `docs/Validation.md` and `docs/Test-Coverage.md` for the latest details.

## Implementation Lessons

WebView preview is the right MVP path. Spike 1 showed it gives much better large-document behavior and preserves semantic Markdown layout more cleanly than the first native attributed-text prototype. Keep parser/rendering behind an adapter so the choice remains reversible if later accessibility, selection, memory, or editing evidence changes the tradeoff.

Use app-owned preview styling. The reading experience depends on local CSS that controls font stack, line height, content width, code blocks, tables, links, and the light palette.

Do not add heavy knowledge-management behavior by accident. Search and outline are document/workspace navigation aids, not a reason to add wiki links, backlinks, graph views, plugins, sync, or a database.

Treat WebView bridge code as crash-sensitive. The search/outline crash came from using `NSJSONSerialization` for a top-level JavaScript string. Keep JavaScript generation small, tested, and isolated in support code.

Treat rendered Markdown as untrusted local content. The MVP supports common Markdown only, so raw HTML is escaped before WebView rendering instead of being executed as document HTML.

Treat filesystem watchers as actor-sensitive. The live-refresh crash came from dispatch-source callbacks crossing actor isolation unexpectedly. Keep watcher callbacks on the queue/actor their state expects, and cover user workflows with crash-report smoke checks.

User-facing automation matters. The smoke suite caught and now guards the important flows: opening, search, outline, shortcuts, folder watching, and crash reports. Add pure unit tests for deterministic logic and UI smoke for SwiftUI/AppKit/WebKit interaction boundaries.

Pane dragging itself should remain manual QA for now. Synthetic macOS drag-coordinate tests were unreliable. The saved pane layout state is unit-tested, and pane visibility is covered by UI smoke.

Visual polish is product work, not garnish. The app should remain light, quiet, readable, and joyful. Avoid heavy visible divider lines; invisible resize hit targets fit the current design better.

Native WebView editing is viable and now has a first production implementation. Spike 4 proved the Candidate A interaction model inside AppKit + `WKWebView`; production editing moved that into the app with saved Markdown smoke coverage. The editor should keep normal read mode beautiful by hiding block syntax and source-only blank lines, only revealing the current line's source marker during intentional Left Arrow marker editing. Editing still needs hardening around IME/input, paste, large files, accessibility, and external file-conflict handling.

## Deferred But Important

- Live-preview editing hardening.
- Broader accessibility pass before distribution.
- Signed/notarized distribution.
- Large-file screenshot/performance smoke.
