# Test Coverage

Last updated: 2026-06-11

This document maps user-focused behavior to automated coverage. The goal is to catch failures before the user does, especially at boundaries between SwiftUI, AppKit, WebKit, filesystem watching, and local files.

## Gates

Run before considering app behavior complete:

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

## Behavior Matrix

| Behavior | Coverage | Notes |
|---|---|---|
| Open a single Markdown file | UI smoke | Launches installed app with `basic.md` and exercises file-level search/shortcuts. |
| Open a folder | UI smoke | Launches installed app with fixture folder and exercises sidebar/navigation. |
| Unified `Cmd+O` open command | UI smoke | Opens the native panel and dismisses it with Escape. |
| Render common Markdown | Unit tests | Verifies headings, emphasis, code, lists, tables, light CSS, and wrapped HTML. |
| Build folder tree | Unit tests | Covers Markdown filtering, hidden files, single-file workspaces, unsupported files, and symlink skipping. |
| Sidebar file selection via keyboard | UI smoke | Uses `Cmd+Down` and `Cmd+Up` across visible Markdown files. |
| Sidebar visible row model | Unit tests | Verifies visible ordering, depth, parent IDs, expansion behavior, and node lookup. |
| Sidebar plain-key navigation | Unit tests and UI smoke | Unit tests cover the visible row model; UI smoke drives plain arrows, `Space`, and `Return` in the sidebar. |
| Search current document | Unit tests and UI smoke | Unit tests verify matching/context; UI smoke opens `Cmd+F`, types queries, and clicks results. |
| Search workspace | Unit tests and UI smoke | Unit tests verify file metadata, snippets, limits, and occurrence numbers; UI smoke searches an opened folder and clicks a cross-file result. |
| Jump from search result into preview | UI smoke | Exercises WebView JavaScript bridge and crash-report checks. |
| Live-preview editing | Unit tests and UI smoke | Unit tests cover editor HTML/script generation; UI smoke edits a paragraph into bullet lines, saves with `Cmd+S`, and verifies the Markdown file on disk. |
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
- Live-preview editing still needs automated coverage for IME/input, undo/redo, paste normalization, richer selection behavior, external file-conflict handling, accessibility, and large-file behavior.

## Standard For New User-Facing Features

Every new user-facing behavior should have at least one of:

- a fast unit test for pure logic;
- an app-support unit test for bridge/script/formatting code;
- a UI smoke step that drives the installed app and checks process/crash-report health.

High-risk UI bridge features need both a unit test and a UI smoke step.
