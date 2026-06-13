# Test Coverage

Last updated: 2026-06-13

This document maps user-focused behavior to automated coverage. The goal is to catch failures before the user does, especially at boundaries between SwiftUI, AppKit, WebKit, filesystem watching, and local files.

## Gates

Run during feature implementation:

```sh
./scripts/test-macos.sh
```

For a quick installed-app health check, run:

```sh
./scripts/smoke-macos-ui.sh
```

Then run the narrowest targeted E2E regression script that covers the changed surface:

```sh
./scripts/smoke-macos-launch-window.sh
./scripts/e2e-macos-navigation.sh
./scripts/e2e-macos-files.sh
./scripts/e2e-macos-editing.sh
./scripts/e2e-macos-code-block-formatting.sh
./scripts/e2e-macos-images.sh
./scripts/e2e-macos-watch.sh
```

Build and install first when installed-app UI automation needs the current app bundle:

```sh
./scripts/build-macos-app.sh
./scripts/install-macos-app.sh
```

Run the full ship/progress gate before shipping or broad progress records, not after every iteration:

```sh
./scripts/test-macos.sh
./scripts/build-macos-app.sh
./scripts/install-macos-app.sh
./scripts/smoke-macos-ui.sh
./scripts/e2e-macos-ui.sh
```

Recommended loop:

- Use `./scripts/test-macos.sh` for pure logic and generated WebView/editor HTML changes.
- Run `./scripts/smoke-macos-ui.sh` when you need a fast confidence check that the installed app can launch, open, edit, save, create, rename, and avoid crash reports.
- Add 2-3 feature-specific assertions to the targeted E2E script for the surface being changed.
- Run only that targeted E2E script during iteration.
- Use `./scripts/smoke-macos-launch-window.sh` for launch placement/display behavior instead of any larger smoke slice.
- Run `./scripts/e2e-macos-ui.sh` when the user asks to ship/record broad progress, or earlier only for cross-cutting/shared-wiring changes.

Run for performance-sensitive changes:

```sh
./scripts/profile-macos.sh spikes/spike1-rendering-engine/fixtures
```

## Behavior Matrix

| Behavior | Coverage | Notes |
|---|---|---|
| Launch smoke starts on the built-in display | UI smoke | `smoke-macos-launch-window.sh` opens one fixture and verifies the Markdown window lands on the built-in display's visible frame without running feature workflows. |
| Open a single Markdown file | UI smoke and UI E2E | Fast smoke opens a single file; `e2e-macos-navigation.sh` also exercises file-level search/shortcuts. |
| Open a folder | UI smoke and UI E2E | Fast smoke opens a folder; `e2e-macos-navigation.sh` exercises sidebar/navigation. |
| Unified `Cmd+O` open command | UI E2E | Opens the native panel and dismisses it with Escape. |
| Create a Markdown file in folder view | UI smoke and UI E2E | Fast smoke creates and renames one file; `e2e-macos-files.sh` verifies `Untitled.md` and `Untitled 2.md`. |
| Hide folders with no Markdown descendants | Unit tests | Workspace tree builder verifies empty/non-Markdown-only child folders are pruned from the visible tree. |
| Rename selected Markdown file | UI smoke and UI E2E | Uses the File menu rename command, edits the native rename prompt, and verifies the file is moved on disk. File rows also expose Rename in their context menu. |
| Render common Markdown | Unit tests | Verifies headings, emphasis, code, lists, tables, light CSS, and wrapped HTML. |
| Render and zoom Markdown images | Unit tests and UI E2E | Unit tests cover generated image parsing/rendering hooks and image URL constraints; `e2e-macos-images.sh` opens a real relative local image, opens the full-window preview, exercises zoom/reset/close shortcuts, saves, and verifies Markdown source is unchanged. |
| Hover and open Markdown links | Unit tests and manual/user verification | Unit tests cover local Markdown vs external `http` / `https` destination resolution, same-document fragments, unsupported schemes/files, and generated WebView hover/activation bridge hooks. The actual `Cmd`/`Ctrl` modifier-click gesture is verified manually because synthetic macOS modifier-clicks against contentEditable WebKit links were unreliable. |
| Build folder tree | Unit tests | Covers Markdown filtering, hidden files, single-file workspaces, unsupported files, and symlink skipping. |
| Sidebar file selection via keyboard | UI E2E | Uses `Cmd+Down` and `Cmd+Up` across visible Markdown files. |
| Sidebar visible row model | Unit tests | Verifies visible ordering, depth, parent IDs, expansion behavior, and node lookup. |
| Sidebar plain-key navigation | Unit tests and UI E2E | Unit tests cover the visible row model; E2E drives plain arrows, `Space`, and `Return` in the sidebar. |
| Search current document | Unit tests, UI smoke, and UI E2E | Unit tests verify matching/context; UI automation opens `Cmd+F`, types queries, and clicks results. |
| Search workspace | Unit tests and UI E2E | Unit tests verify file metadata, snippets, limits, and occurrence numbers; E2E searches an opened folder and clicks a cross-file result. |
| Jump from search result into preview | UI E2E | Exercises WebView JavaScript bridge and crash-report checks. |
| Live-preview editing | Unit tests, UI smoke, and UI E2E | Unit tests cover editor HTML/script generation; fast smoke verifies one edit/save path; E2E covers paragraph, bullet, and ordered-list saves. |
| Autosave while editing | UI E2E | Types into a newly-created blank file, waits for debounce, and verifies the Markdown file on disk without pressing `Cmd+S`. |
| Ordered-list exit while editing | UI E2E | Presses `Return` twice after `1.` / `2.` / `3.`, types normal paragraph text, saves, and verifies no empty `4.` item is written. |
| Blank-line paragraph editing | UI E2E | Types into an existing blank line, verifies text survives `Return`, and verifies text survives blur plus autosave. |
| Selection formatting while editing | Unit tests and UI E2E | Unit tests cover formatting toolbar/script generation; E2E selects all text, applies bold with `Cmd+B`, inline code with `Cmd+E`, link with `Cmd+K`, highlight with `Cmd+Control+H`, saves, and verifies Markdown wrappers on disk. |
| Fenced-code formatting | Unit tests and UI E2E | Unit tests cover generated editor hooks; `e2e-macos-code-block-formatting.sh` opens a fenced Swift code block, uses Left Arrow marker editing, deletes the opening fence, saves, and verifies the code block unwraps on disk. It also verifies Backspace removes an empty code line while preserving the fence, and checks single-line extraction from fenced code. |
| Copy Markdown from editor | Unit tests and UI E2E | Unit tests cover generated copy controls/script hooks; E2E clicks the whole-document copy button and a fenced-code-section copy button, then verifies `pbpaste` contains Markdown. |
| Live-preview undo/redo | Unit tests and UI E2E | Unit tests cover editor history script generation; E2E edits a paragraph, saves after `Cmd+Z`, verifies original file content, then saves after `Shift+Cmd+Z` and verifies redone content. |
| Marker replacement editing | UI E2E | Focuses a list item, uses Left Arrow marker replacement, saves, and verifies `* One` becomes `> One` on disk. |
| Right outline panel | Unit tests and UI E2E | Unit tests verify outline extraction; E2E clicks outline landmarks. |
| Toggle left sidebar | UI E2E | Uses `Cmd+Left Arrow`. |
| Toggle right outline | UI E2E | Uses `Cmd+Right Arrow`. |
| Pane size and visibility restoration | Unit tests and UI E2E | Unit tests cover saved-state load/save, legacy preference migration, and width clamping. E2E covers pane visibility toggles. Dragging remains manual because synthetic pane drags are flaky on macOS. |
| Help keyboard shortcut reference | UI E2E | Uses `Cmd+/` and dismisses the sheet. |
| Reveal selected file in Finder | UI E2E | Uses `Cmd+R`; E2E checks app survival and crash reports. |
| Folder change awareness | UI E2E | Adds and deletes a Markdown file in an opened folder. |
| Selected-file rename/delete | Unit tests and UI E2E | Unit tests verify replacement selection during rebuilds; E2E renames and deletes the selected file and deletes the final Markdown file. |
| File change awareness | UI E2E | Adds/deletes files in opened folders and guards selected-file churn; dirty same-file external conflict behavior remains a hardening gap. |
| Resource readout | Manual/profile currently | Profile gate covers idle CPU/RSS; formatting/throttling should get unit tests when extracted. |
| Editing/update-mode spike | Spike unit tests | `swift test --package-path spikes/spike2-editing-update-mode` covers line-model round-trip and marker-preserving edits. |
| Candidate A WebView editor spike | Spike unit tests | `node --test spikes/spike3-candidate-a-webview-editor/tests/*.test.mjs` covers browser-model round-trip, marker-preserving edits, unlock, type changes, and shortcut classification. |
| Native Candidate A WebView editor spike | Spike unit tests and native smoke | `spikes/spike4-native-webview-editor/scripts/smoke-native-editor.sh` covers Swift bridge parsing plus native `WKWebView` load/edit/unlock/marker-selection/commit/re-render/serialize behavior. |
| Focused accessibility spot check | Manual/AX smoke | Confirms standard accessibility window, keyboard-only sidebar path, and explicit labels for icon-only controls. Broader VoiceOver audit remains future distribution work. |
| Crash report regression | UI smoke and UI E2E | Fails if a new `Markdown-*.ips` appears during the run. |

## Known Coverage Gaps

- The fast UI smoke is intentionally shallow; deeper user workflows live in targeted E2E scripts.
- UI E2E does not yet assert rendered text through accessibility; it currently verifies disk/clipboard outcomes, process survival, and crash reports while driving user workflows.
- Plain-arrow folder-row selection is not complete product behavior yet, so coverage remains pending.
- Selected-file live refresh should get automated E2E coverage that edits the selected file on disk.
- Resource readout formatting and throttling should be moved into a testable support module.
- Pane dragging itself is manual QA; the persisted layout state has automated coverage.
- Actual modifier-click link opening is manual QA; deterministic resolver and generated WebView bridge behavior are unit-tested.
- Visual polish remains screenshot/manual QA rather than pixel-diff automation.
- Live-preview editing still needs automated coverage for IME/input, paste normalization, cross-block selection behavior, external file-conflict handling, accessibility, and large-file behavior.

## Standard For New User-Facing Features

Every new user-facing behavior should have at least one of:

- a fast unit test for pure logic;
- an app-support unit test for bridge/script/formatting code;
- a targeted UI E2E step that drives the installed app and checks process/crash-report health.

High-risk UI bridge features need both a unit test and a targeted UI E2E step. The fast smoke should stay small enough to be useful during everyday iteration.
