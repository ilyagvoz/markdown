# Validation

Last updated: 2026-06-11

## Automated Gates

Run:

```sh
./scripts/test-macos.sh
```

Latest result:

- Passed.
- 20 unit tests.
- Coverage areas: Markdown HTML rendering, light-only CSS contract, outline/landmark extraction, current-document search, workspace search result metadata/snippets, visible sidebar row navigation, WebView JavaScript string/script generation, restored pane layout state, folder tree building, single-file workspace, unsupported file rejection, symbolic-link skipping.

Run:

```sh
./scripts/build-macos-app.sh
```

Latest result:

- Passed.
- Produces the release app bundle at `artifacts/Markdown.app`.

Run:

```sh
./scripts/install-macos-app.sh
```

Latest result:

- Passed.
- Installs `/Applications/Markdown.app`.

Run after interactive WebView/sidebar changes:

```sh
./scripts/smoke-macos-ui.sh
```

Latest result:

- Passed.
- Launches the installed app against a single file, a folder, and a temporary watched folder.
- Drives `Cmd+O`, `Cmd+F`, `Cmd+/`, `Cmd+Up`, `Cmd+Down`, `Cmd+Left Arrow`, `Cmd+Right Arrow`, `Cmd+R`, plain sidebar arrows, `Space`, `Return`, outline clicks, current-document search-result clicks, workspace search-result clicks, and folder add/delete events.
- Fails if the app exits unexpectedly or a new `Markdown-*.ips` report appears.

See `docs/Test-Coverage.md` for the user-focused coverage matrix.

Run:

```sh
./scripts/profile-macos.sh spikes/spike1-rendering-engine/fixtures
```

Latest release-profile result:

| Metric | Observation |
|---|---:|
| Settled idle CPU | 0.0-0.1% on later samples |
| Fixture settled RSS | about 91.6 MB |
| Larger-folder settled RSS | about 116.6 MB against `~/dev/distill-v3/docs` |
| Launch/render RSS range | about 91.6-122.8 MB in the latest release-profile runs |
| Virtual size | very large, expected for modern macOS/WebKit process address space and not useful as real memory pressure |

In the managed Codex sandbox, SwiftPM may warn that user-level SwiftPM configuration/security paths under `~/Library` are not writable. The project scripts keep scratch space and caches inside the workspace; those warnings do not fail the gate.

## Manual / Visual QA

Validated screenshots:

- `artifacts/screenshots/markdown-mvp-03-light.png` - folder-open flow with collapsible sidebar and rendered `basic.md`.
- `artifacts/screenshots/markdown-mvp-04-single-file.png` - single-file open flow with rendered table fixture.
- `artifacts/screenshots/markdown-next-01-outline-search.png` - three-pane outline flow with fixtures.
- `artifacts/screenshots/markdown-next-02-folder-watch.png` - folder watcher after adding `added-later.md` without reopening.
- `artifacts/screenshots/markdown-next-03-folder-delete.png` - folder watcher after deleting `added-later.md`.
- `artifacts/screenshots/markdown-next-04-search.png` - `Cmd+F` current-document search with result chips.
- `artifacts/screenshots/markdown-next-05-toggle-outline.png` - `Cmd+Right Arrow` hides the outline while search is focused.
- `artifacts/screenshots/markdown-next-06-final-fixtures.png` - final three-pane fixture flow.
- `artifacts/screenshots/markdown-next-07-shortcuts-help.png` - Help keyboard shortcuts sheet.
- `artifacts/screenshots/markdown-pane-persistence-invisible-dividers.png` - pane persistence build with invisible resize hit targets.

Assessment:

- Function: single-file and folder-open flows work.
- Usability: sidebar hierarchy is clear, selected file is obvious, current-document search is discoverable, the outline panel is useful without overpowering the reading surface, and status text remains unobtrusive.
- Joy: the light-only palette, warm paper reading surface, teal selection, calm three-pane layout, and comfortable typography are directionally right for daily use.

Known UX follow-ups:

- Add the editing/update-mode spike.
- Add a first-run empty-state screenshot pass once the app has an icon and final window sizing.

## Feature Smoke

Folder watch:

- Opened a temporary folder containing `alpha.md` and `notes/nested.md`.
- Added `added-later.md` on disk while the app was open.
- Verified `added-later.md` appeared in the sidebar without reopening.
- Deleted `added-later.md` on disk.
- Verified it disappeared from the sidebar without reopening.
- Verified the app process stayed alive.

Keyboard/search:

- `Cmd+F` opened the current-document search UI and accepted typed input.
- Search results showed heading context and snippets.
- Workspace search showed file paths, heading context, and snippets across an opened folder.
- Clicking a workspace search result selected the target file and ran the existing preview find action.
- Plain sidebar keys moved the highlighted row, toggled folder expansion, and activated a highlighted Markdown file while the app stayed alive.
- `Cmd+Right Arrow` hid the right outline panel while search focus was active.
- `Cmd+/` opened the keyboard shortcut reference sheet.

Pane persistence:

- Left sidebar and right outline widths are now stored in restored app state.
- Left sidebar and right outline visibility are stored in restored app state.
- Added unit coverage for save/load, older preference migration, and pane width clamping.
- Kept pane resize hit targets invisible; no heavy divider lines are shown in the UI.
- Did not add synthetic drag UI automation because macOS drag-coordinate tests were unreliable; drag behavior remains manual QA while persistence logic is automated.

## Crash Fix

2026-06-10: A crash was observed after adding live file refresh. The latest crash report was:

`~/Library/Logs/DiagnosticReports/Markdown-2026-06-10-230944.ips`

Root cause:

- `FileWatcher` was `@MainActor`.
- Its `DispatchSourceFileSystemObject` event handler ran on a utility queue.
- Swift runtime actor isolation trapped on the cross-actor handler.

Fix:

- File-system events now dispatch on `DispatchQueue.main`, matching `FileWatcher`'s main-actor isolation.

Verification:

- `./scripts/test-macos.sh` passed.
- `./scripts/build-macos-app.sh` passed.
- `./scripts/install-macos-app.sh` passed.
- Live-edit smoke: opened `/tmp/markdown-live-test/live.md`, edited it on disk, verified the app process stayed alive and no new `Markdown-*.ips` crash report was created.

2026-06-11: Two crashes were observed after adding outline/search jump behavior. The fresh crash reports were:

- `~/Library/Logs/DiagnosticReports/Markdown-2026-06-11-121548.ips`
- `~/Library/Logs/DiagnosticReports/Markdown-2026-06-11-121549.ips`

Root cause:

- The faulting stack was `MarkdownWebPreview.Coordinator.execute(...)`.
- The WebView bridge used `NSJSONSerialization.data(withJSONObject:)` to encode a top-level Swift `String` as a JavaScript string literal.
- On this OS, that invalid top-level JSON object raised an Objective-C exception inside `NSJSONSerialization`, which AppKit converted into an `EXC_BREAKPOINT` crash.

Fix:

- Replaced `NSJSONSerialization` with `JSONEncoder().encode(value)` for JavaScript string-literal generation.
- This safely encodes top-level strings and avoids Objective-C exception behavior.

Verification:

- `./scripts/test-macos.sh` passed.
- `./scripts/build-macos-app.sh` passed.
- `./scripts/install-macos-app.sh` passed.
- Outline jump smoke: launched `outline.md`, clicked an outline item, verified the app process stayed alive and no new `Markdown-*.ips` crash report appeared.
- Search jump smoke: opened `Cmd+F`, searched `diagram`, clicked a result, verified the app process stayed alive and no new `Markdown-*.ips` crash report appeared.

2026-06-11 follow-up:

- A later user-observed crash/termination did not produce a new `Markdown-*.ips` report; the newest reports remained the `12:15:48` and `12:15:49` reports above.
- Added defensive WebView action handling anyway:
  - pending preview actions now wait until WebView navigation finishes;
  - action tokens reset on reload;
  - JavaScript evaluation completion ignores page-side errors instead of feeding them into SwiftUI updates.
- Rebuilt and installed `/Applications/Markdown.app`.
- Ran four repeated smoke iterations opening `outline.md`, clicking outline items, using `Cmd+F`, clicking search results, and toggling the right outline. The app process stayed alive each time and no new crash report appeared.
