# Validation History

This document keeps older smoke transcripts, manual QA notes, and crash investigations that are still useful but too detailed for `docs/Validation.md`.

Use `docs/Validation.md` for the latest gate results and `docs/Test-Coverage.md` for the canonical test-selection matrix.

## Feature Smoke History

Folder new-file creation:

- Opened a temporary empty folder.
- Used `Cmd+N` to create `Untitled.md`.
- Typed into the newly-created blank file, waited for autosave debounce without pressing `Cmd+S`, and verified the file on disk was exactly `From scratch` followed by `Second line`.
- Used `Cmd+N` again and verified `Untitled 2.md` was created without overwriting the first file.

Rename:

- Opened a temporary folder containing `RenameMe.md`.
- Used the File menu rename command to open the native rename prompt.
- Entered `Renamed`.
- Verified `RenameMe.md` moved to `Renamed.md`.
- File rows also expose Rename from the right-click context menu.

Folder watch:

- Opened a temporary folder containing `alpha.md` and `notes/nested.md`.
- Added and deleted `added-later.md` on disk while the app was open, and verified the sidebar updated without reopening.
- Renamed and deleted the selected Markdown file on disk, including the final Markdown file in the folder, and verified the app stayed alive without stale-preview crashes or a new crash report.

Live-preview editing:

- Verified paragraph editing plus two typed bullet lines save as Markdown.
- Verified ordered-list continuation and ordered-list exit behavior.
- Verified typing into existing blank lines survives `Return`, blur, autosave, and explicit save.
- Verified whole-document and fenced-code-section Markdown copy controls through `pbpaste`.
- Verified marker replacement can turn `* One` into `> One`.
- Verified single-line extraction from a fenced code block using `scripts/fixtures/code-line-extraction.md`.
- Verified Backspace removes one empty code line while preserving the surrounding fence.
- Verified selection formatting for bold, highlight, inline code, and links.
- Verified app-owned undo/redo saves original and redone content correctly.

Keyboard/search:

- `Cmd+F` opened current-document search and accepted typed input.
- Search results showed heading context and snippets.
- Workspace search showed file paths, heading context, and snippets across an opened folder.
- Clicking a workspace search result selected the target file and ran the preview find action.
- Plain sidebar keys moved the highlighted row, toggled folder expansion, and activated a Markdown file while the app stayed alive.
- `Cmd+Right Arrow` hid the right outline panel while search focus was active.
- `Cmd+/` opened the keyboard shortcut reference sheet.

Pane persistence:

- Left sidebar and right outline widths are stored in restored app state.
- Left sidebar and right outline visibility are stored in restored app state.
- Unit coverage verifies save/load, older preference migration, and pane width clamping.
- Pane resize hit targets remain invisible; no heavy divider lines are shown.
- Synthetic drag UI automation was not added because macOS drag-coordinate tests were unreliable. Drag behavior remains manual QA while persistence logic is automated.

App identity:

- Added `AppIcon.icns` and a full iconset under `apps/macos/Markdown/Resources`.
- Added `CFBundleIconFile`, Markdown document type metadata, and productivity app category metadata to `Info.plist`.
- Updated `build-macos-app.sh` to copy resource files into `Contents/Resources`.
- Verified `/Applications/Markdown.app/Contents/Resources/AppIcon.icns` exists after install.

Editing/update-mode spike validation:

- Added `spikes/spike2-editing-update-mode` Swift package.
- Added a tested Markdown line-model prototype for preserving presentation markers during ordinary visible-text edits.
- Recommendation: prototype production editing with a WebView-backed live-preview editor first, while keeping Markdown serialization in an app-owned Swift line/block model.
- Production editing has since shipped its first implementation; remaining hardening lives in `docs/Next-Steps.md`.

Candidate A WebView editor spike validation:

- Added `spikes/spike3-candidate-a-webview-editor` static WebView/editor prototype.
- Added dependency-free browser model tests using Node's built-in test runner.
- Recommendation: proceed to a native macOS `WKWebView` editor spike or debug view next, with Swift as the authoritative Markdown serializer and DOM state treated as interaction state only.
- Automated browser screenshot was not captured because Playwright was not installed in the runtime; the static prototype remains manually inspectable via a local server.

Native Candidate A WebView editor spike validation:

- Added `spikes/spike4-native-webview-editor` Swift package.
- Added an AppKit `WKWebView` host with a narrow JavaScript-to-Swift bridge.
- Added a side-by-side native source/status panel for inspecting serialized Markdown state.
- Added `--smoke` mode that loads WebKit, edits a heading while preserving `#`, unlocks a list item, changes it to a quote, verifies serialized Markdown and rendered block type from Swift, and terminates.
- Refined raw-marker editing after manual UX feedback: Left Arrow now preselects the Markdown marker, typed marker replacement can apply quickly without cursor repositioning, unlocked lines commit and re-render on Return/blur/live-edit debounce, and smoke coverage verifies list-to-quote conversion renders as a quote rather than remaining raw.
- Found that local ES module imports from the SwiftPM resource bundle did not initialize reliably in native smoke; the spike uses a self-contained classic script for the native WebView resource.
- Recommendation was accepted: production editing proceeded with app-owned canonical Markdown state and WebView interaction state.

Accessibility spot check:

- Verified the app exposes a standard macOS accessibility window through System Events.
- Drove the keyboard-only sidebar path with plain arrows, `Space`, and `Return`; the app stayed alive and did not trap the key path.
- Added explicit accessibility labels for icon-only search, outline, clear-search, and hide-outline controls.
- Sidebar file/folder rows include explicit file/folder accessibility labels in code.
- System Events did not expose enough SwiftUI child labels to act as a full accessibility audit, so a broader hands-on VoiceOver pass remains a future distribution-quality task.

## Crash Fix History

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
- Live-edit smoke opened `/tmp/markdown-live-test/live.md`, edited it on disk, verified the app process stayed alive, and verified no new `Markdown-*.ips` crash report was created.

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
- Outline jump smoke launched `outline.md`, clicked an outline item, verified the app process stayed alive, and verified no new `Markdown-*.ips` crash report appeared.
- Search jump smoke opened `Cmd+F`, searched `diagram`, clicked a result, verified the app process stayed alive, and verified no new `Markdown-*.ips` crash report appeared.

2026-06-11 follow-up:

- A later user-observed crash/termination did not produce a new `Markdown-*.ips` report; the newest reports remained the `12:15:48` and `12:15:49` reports above.
- Added defensive WebView action handling:
  - pending preview actions now wait until WebView navigation finishes;
  - action tokens reset on reload;
  - JavaScript evaluation completion ignores page-side errors instead of feeding them into SwiftUI updates.
- Rebuilt and installed `/Applications/Markdown.app`.
- Ran four repeated smoke iterations opening `outline.md`, clicking outline items, using `Cmd+F`, clicking search results, and toggling the right outline. The app process stayed alive each time and no new crash report appeared.
