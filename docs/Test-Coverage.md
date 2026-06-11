# Test Coverage

Last updated: 2026-06-11

This document maps user-focused behavior to automated coverage. The goal is to catch failures before the user does, especially at boundaries between SwiftUI, AppKit, WebKit, filesystem watching, and local files.

## Gates

Run during feature implementation:

```sh
./scripts/test-macos.sh
```

Then run the narrowest focused smoke script that covers the changed surface:

```sh
./scripts/smoke-macos-launch-window.sh
./scripts/smoke-macos-navigation.sh
./scripts/smoke-macos-files.sh
./scripts/smoke-macos-editing.sh
./scripts/smoke-macos-watch.sh
```

Build and install first when the focused smoke needs the installed app:

```sh
./scripts/build-macos-app.sh
./scripts/install-macos-app.sh
```

Run the full battery as the pre-commit/progress gate, not after every iteration:

```sh
./scripts/test-macos.sh
./scripts/build-macos-app.sh
./scripts/install-macos-app.sh
./scripts/smoke-macos-ui.sh
```

Recommended loop:

- Use `./scripts/test-macos.sh` for pure logic and generated WebView/editor HTML changes.
- Add 2-3 feature-specific smoke assertions to the focused script for the surface being changed.
- Run only that focused script during iteration.
- Use `./scripts/smoke-macos-launch-window.sh` for launch placement/display behavior instead of any larger smoke slice.
- Run `./scripts/smoke-macos-ui.sh` when the user asks to commit/ship/record progress, or earlier only for cross-cutting/shared-wiring changes.

Run for performance-sensitive changes:

```sh
./scripts/profile-macos.sh spikes/spike1-rendering-engine/fixtures
```

## Behavior Matrix

| Behavior | Coverage | Notes |
|---|---|---|
| Launch smoke starts on the built-in display | UI smoke | `smoke-macos-launch-window.sh` opens one fixture and verifies the Markdown window lands on the built-in display's visible frame without running feature workflows. |
| Open a single Markdown file | UI smoke | Launches installed app with `basic.md` and exercises file-level search/shortcuts. |
| Open a folder | UI smoke | Launches installed app with fixture folder and exercises sidebar/navigation. |
| Unified `Cmd+O` open command | UI smoke | Opens the native panel and dismisses it with Escape. |
| Create a Markdown file in folder view | UI smoke | Opens a temporary empty folder, uses `Cmd+N`, verifies `Untitled.md`, repeats, and verifies `Untitled 2.md`. |
| Hide folders with no Markdown descendants | Unit tests | Workspace tree builder verifies empty/non-Markdown-only child folders are pruned from the visible tree. |
| Rename selected Markdown file | UI smoke | Uses the File menu rename command, edits the native rename prompt, and verifies the file is moved on disk. File rows also expose Rename in their context menu. |
| Render common Markdown | Unit tests | Verifies headings, emphasis, code, lists, tables, light CSS, and wrapped HTML. |
| Build folder tree | Unit tests | Covers Markdown filtering, hidden files, single-file workspaces, unsupported files, and symlink skipping. |
| Sidebar file selection via keyboard | UI smoke | Uses `Cmd+Down` and `Cmd+Up` across visible Markdown files. |
| Sidebar visible row model | Unit tests | Verifies visible ordering, depth, parent IDs, expansion behavior, and node lookup. |
| Sidebar plain-key navigation | Unit tests and UI smoke | Unit tests cover the visible row model; UI smoke drives plain arrows, `Space`, and `Return` in the sidebar. |
| Search current document | Unit tests and UI smoke | Unit tests verify matching/context; UI smoke opens `Cmd+F`, types queries, and clicks results. |
| Search workspace | Unit tests and UI smoke | Unit tests verify file metadata, snippets, limits, and occurrence numbers; UI smoke searches an opened folder and clicks a cross-file result. |
| Jump from search result into preview | UI smoke | Exercises WebView JavaScript bridge and crash-report checks. |
| Live-preview editing | Unit tests and UI smoke | Unit tests cover editor HTML/script generation; UI smoke edits a paragraph into bullet lines and ordered `1.` / `2.` / `3.` lines, saves with `Cmd+S`, and verifies the Markdown file on disk. |
| Autosave while editing | UI smoke | Types into a newly-created blank file, waits for debounce, and verifies the Markdown file on disk without pressing `Cmd+S`. |
| Ordered-list exit while editing | UI smoke | Presses `Return` twice after `1.` / `2.` / `3.`, types normal paragraph text, saves, and verifies no empty `4.` item is written. |
| Blank-line paragraph editing | UI smoke | Types into an existing blank line, verifies text survives `Return`, and verifies text survives blur plus autosave. |
| Selection formatting while editing | Unit tests and UI smoke | Unit tests cover formatting toolbar/script generation; UI smoke selects all text, applies bold with `Cmd+B`, inline code with `Cmd+E`, link with `Cmd+K`, highlight with `Cmd+Control+H`, saves, and verifies Markdown wrappers on disk. |
| Copy Markdown from editor | Unit tests and UI smoke | Unit tests cover generated copy controls/script hooks; UI smoke clicks the whole-document copy button and a fenced-code-section copy button, then verifies `pbpaste` contains Markdown. |
| Live-preview undo/redo | Unit tests and UI smoke | Unit tests cover editor history script generation; UI smoke edits a paragraph, saves after `Cmd+Z`, verifies original file content, then saves after `Shift+Cmd+Z` and verifies redone content. |
| Marker replacement editing | UI smoke | Focuses a list item, uses Left Arrow marker replacement, saves, and verifies `* One` becomes `> One` on disk. |
| Right outline panel | Unit tests and UI smoke | Unit tests verify outline extraction; UI smoke clicks outline landmarks. |
| Toggle left sidebar | UI smoke | Uses `Cmd+Left Arrow`. |
| Toggle right outline | UI smoke | Uses `Cmd+Right Arrow`. |
| Pane size and visibility restoration | Unit tests and UI smoke | Unit tests cover saved-state load/save, legacy preference migration, and width clamping. UI smoke covers pane visibility toggles. Dragging remains manual because synthetic pane drags are flaky on macOS. |
| Help keyboard shortcut reference | UI smoke | Uses `Cmd+/` and dismisses the sheet. |
| Reveal selected file in Finder | UI smoke | Uses `Cmd+R`; smoke checks app survival and crash reports. |
| Folder change awareness | UI smoke | Adds and deletes a Markdown file in an opened folder. |
| Selected-file rename/delete | Unit tests and UI smoke | Unit tests verify replacement selection during rebuilds; UI smoke renames and deletes the selected file and deletes the final Markdown file. |
| File change awareness | UI smoke | Adds/deletes files in opened folders and guards selected-file churn; dirty same-file external conflict behavior remains a hardening gap. |
| Resource readout | Manual/profile currently | Profile gate covers idle CPU/RSS; formatting/throttling should get unit tests when extracted. |
| Editing/update-mode spike | Spike unit tests | `swift test --package-path spikes/spike2-editing-update-mode` covers line-model round-trip and marker-preserving edits. |
| Candidate A WebView editor spike | Spike unit tests | `node --test spikes/spike3-candidate-a-webview-editor/tests/*.test.mjs` covers browser-model round-trip, marker-preserving edits, unlock, type changes, and shortcut classification. |
| Native Candidate A WebView editor spike | Spike unit tests and native smoke | `spikes/spike4-native-webview-editor/scripts/smoke-native-editor.sh` covers Swift bridge parsing plus native `WKWebView` load/edit/unlock/marker-selection/commit/re-render/serialize behavior. |
| Focused accessibility spot check | Manual/AX smoke | Confirms standard accessibility window, keyboard-only sidebar path, and explicit labels for icon-only controls. Broader VoiceOver audit remains future distribution work. |
| Crash report regression | UI smoke | Fails if a new `Markdown-*.ips` appears during the run. |

## Known Coverage Gaps

- The UI smoke does not yet assert rendered text through accessibility; it currently verifies process survival and crash reports while driving user workflows.
- Plain-arrow folder-row selection is not complete product behavior yet, so coverage remains pending.
- Selected-file live refresh should get an automated smoke that edits the selected file on disk.
- Resource readout formatting and throttling should be moved into a testable support module.
- Pane dragging itself is manual QA; the persisted layout state has automated coverage.
- Visual polish remains screenshot/manual QA rather than pixel-diff automation.
- Live-preview editing still needs automated coverage for IME/input, paste normalization, cross-block selection behavior, external file-conflict handling, accessibility, and large-file behavior.

## Standard For New User-Facing Features

Every new user-facing behavior should have at least one of:

- a fast unit test for pure logic;
- an app-support unit test for bridge/script/formatting code;
- a UI smoke step that drives the installed app and checks process/crash-report health.

High-risk UI bridge features need both a unit test and a UI smoke step.
