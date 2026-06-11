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
| Search current document | Unit tests and UI smoke | Unit tests verify matching/context; UI smoke opens `Cmd+F`, types queries, and clicks results. |
| Jump from search result into preview | UI smoke | Exercises WebView JavaScript bridge and crash-report checks. |
| Right outline panel | Unit tests and UI smoke | Unit tests verify outline extraction; UI smoke clicks outline landmarks. |
| Toggle left sidebar | UI smoke | Uses `Cmd+Left Arrow`. |
| Toggle right outline | UI smoke | Uses `Cmd+Right Arrow`. |
| Pane size and visibility restoration | Unit tests and UI smoke | Unit tests cover saved-state load/save, legacy preference migration, and width clamping. UI smoke covers pane visibility toggles. Dragging remains manual because synthetic pane drags are flaky on macOS. |
| Help keyboard shortcut reference | UI smoke | Uses `Cmd+/` and dismisses the sheet. |
| Reveal selected file in Finder | UI smoke | Uses `Cmd+R`; smoke checks app survival and crash reports. |
| Folder change awareness | UI smoke | Adds and deletes a Markdown file in an opened folder. |
| File change awareness | Manual smoke currently | Needs an automated smoke that edits the selected file and verifies app survival/no crash report. |
| Resource readout | Manual/profile currently | Profile gate covers idle CPU/RSS; formatting/throttling should get unit tests when extracted. |
| Crash report regression | UI smoke | Fails if a new `Markdown-*.ips` appears during the run. |

## Known Coverage Gaps

- The UI smoke does not yet assert rendered text through accessibility; it currently verifies process survival and crash reports while driving user workflows.
- Plain-arrow folder-row selection is not complete product behavior yet, so coverage remains pending.
- Selected-file live refresh should get an automated smoke that edits the selected file on disk.
- Resource readout formatting and throttling should be moved into a testable support module.
- Pane dragging itself is manual QA; the persisted layout state has automated coverage.
- Visual polish remains screenshot/manual QA rather than pixel-diff automation.

## Standard For New User-Facing Features

Every new user-facing behavior should have at least one of:

- a fast unit test for pure logic;
- an app-support unit test for bridge/script/formatting code;
- a UI smoke step that drives the installed app and checks process/crash-report health.

High-risk UI bridge features need both a unit test and a UI smoke step.
