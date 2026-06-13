# Engineering Standards

Markdown should be built as a small, reliable macOS app: fast by default, explicit at boundaries, conservative with local files, and easy to reason about in future sessions.

## Core Principles

- Prefer small modules with one reason to change.
- Keep filesystem traversal, parsing, rendering, and UI state in separate boundaries.
- Treat local disk as fallible: files can move, disappear, be unreadable, be huge, or contain unexpected encodings.
- Keep UI responsive. Do filesystem and rendering work off the main actor unless the API requires main-thread access.
- Make risky architecture choices through spikes before locking them into product code.
- Test behavior, not implementation trivia.
- Avoid hidden indexing, background scanning, or persistent databases until product need is proven.
- Keep the app local-first and privacy-preserving.

## Project Boundaries

Use clear ownership boundaries.

### macOS App

Suggested boundaries:

- `App`: app entry point, window setup, scene commands, app-level dependency wiring.
- `Features/OpenDocument`: file and folder opening flows.
- `Features/Sidebar`: workspace tree, expansion state, selection, keyboard navigation.
- `Features/Preview`: rendered document display, scroll behavior, link/image handling.
- `Core/Filesystem`: file discovery, URL security scope handling when needed, metadata, change observation.
- `Core/Markdown`: parser and renderer adapters behind a stable internal interface.
- `Core/Settings`: small user preferences such as appearance or sidebar width.
- `Core/Diagnostics`: local logs and debug instrumentation for performance issues.

Rules:

- SwiftUI views should be thin. They render state and send user intents.
- Filesystem traversal should not live in views.
- Markdown parser-specific types should not leak through the whole app.
- Rendering decisions should be isolated behind an adapter so the spike result can be implemented without rewriting navigation.
- File writes are out of MVP unless editing is explicitly added later.

### Packages

The repo may start with no shared packages. Add packages only when they remove real complexity.

Candidate future packages:

- `MarkdownCore`: parser-neutral document model, renderer protocol, and tests.
- `FilesystemCore`: workspace tree builder and file watcher abstractions.
- `MarkdownFixtures`: reusable renderer fixtures and expected outputs.

Do not create packages just to look like a monorepo. Product code can begin inside `apps/macos`.

### Spikes

Use spikes for decisions with meaningful technical uncertainty.

Each spike should include:

- question
- options
- pass/fail criteria
- smallest useful implementation
- measurements or observations
- final recommendation

Spike code should not become production code by accident. Copy ideas forward deliberately.

## Markdown Standards

MVP targets common Markdown only.

Required behavior:

- Render headings, paragraphs, emphasis, lists, links, code, blockquotes, images, and horizontal rules.
- Handle malformed Markdown without crashing.
- Preserve document order and expected text selection behavior.
- Use readable typography and spacing.
- Use app-owned local CSS for WebView preview styling.
- Keep MVP preview styling light-only.
- Explicitly control fonts, line height, document width, heading scale, paragraph/list spacing, tables, links, and code blocks.
- Avoid custom Markdown dialect features until explicitly accepted through ADR.

Out of scope:

- Obsidian wiki links and backlinks.
- Plugin syntax.
- Graph views.
- Dataview-style queries.
- Live preview editing.

## Filesystem Standards

Local files are the product boundary.

Required behavior:

- Support `.md` and `.markdown` files.
- Ignore hidden/system folders by default unless the user explicitly opens a hidden file.
- Do not follow symlink loops.
- Handle permission failures per file/folder without failing the whole workspace.
- Keep path handling URL-based where possible.
- Avoid reading entire deep folder trees on the main thread.
- Debounce filesystem change notifications if live updates are added.

Edge cases to cover:

- empty folder
- folder with no Markdown files
- deeply nested folder
- large Markdown file
- deleted selected file
- renamed selected file
- unreadable file
- unsupported encoding
- broken local image path
- symlink cycle

## Performance Standards

Performance is a feature.

Measure before choosing architecture for:

- render latency
- file switch latency
- memory usage after repeated renders
- scroll responsiveness on large documents
- app responsiveness during folder traversal

Implementation rules:

- Keep expensive work off the main actor.
- Cache only when measurement shows it helps.
- Bound caches by size or count.
- Prefer incremental folder loading if full traversal becomes slow.
- Avoid global mutable state for selected file, tree expansion, or renderer state.

## Testing Standards

Every module should have tests proportional to risk and blast radius.

Unit tests should cover:

- workspace tree building
- Markdown file filtering
- symlink and hidden-file handling
- parser/renderer adapter behavior
- WebView bridge string/script generation
- error mapping for unreadable or missing files
- selection and expansion state reducers if modeled separately

Integration or UI tests should cover:

- open single file
- open folder
- expand/collapse nested folder
- select file and render preview
- file deleted while selected
- large-file smoke path
- outline item click and WebView jump
- current-document search and search-result jump
- app-level shortcuts while focus is in WebView/search/outline
- crash-report checks around UI automation interactions

### Test Selection Policy

Default to the smallest test set that can catch the bug or regression in the area being changed. Iteration speed is part of engineering quality; avoid running the full UI E2E battery after every small edit.

During feature implementation:

- Run `./scripts/test-macos.sh` when touching Swift logic, generated WebView/editor HTML, parser/search/tree behavior, or bridge code.
- Run `./scripts/build-macos-app.sh` and `./scripts/install-macos-app.sh` when installed-app UI automation is needed.
- Run `./scripts/smoke-macos-ui.sh` for a fast health check after app wiring or install changes.
- Run only the targeted E2E regression script that covers the current feature surface.
- Prefer adding a feature-specific assertion to an existing targeted E2E script over relying on the full E2E battery.

UI automation tiers:

```sh
./scripts/smoke-macos-launch-window.sh
./scripts/smoke-macos-ui.sh
./scripts/e2e-macos-navigation.sh
./scripts/e2e-macos-files.sh
./scripts/e2e-macos-editing.sh
./scripts/e2e-macos-code-block-formatting.sh
./scripts/e2e-macos-images.sh
./scripts/e2e-macos-watch.sh
```

Smoke harness window behavior:

- `smoke-macos-launch-window.sh` is the narrow smoke check for launch placement. Use it when changing app launch, smoke harness startup, window sizing, display selection, or saved-window-frame behavior.
- `smoke-macos-ui.sh` is the fast installed-app smoke check for launch, single-file open, folder open, search, edit/save, new file, rename, and crash-report checks.
- Smoke launches should pass `--smoke-window-frame-default` so the app suppresses startup auto-activation, allowing the harness to launch hidden, place the window on the built-in display, then activate it.
- Before launching the app, smoke scripts should also seed SwiftUI's saved `NSWindow Frame ... AppWindow` defaults for the built-in display's visible frame when a built-in display is available.
- Post-launch placement is only a safety check; the app should not visibly open on one screen and then jump to another during normal smoke runs.
- Do not hard-code one-off window positions that can drift across external displays.
- Keep repositioning to launch/focus setup only; individual smoke steps should not resize or drag the app window.
- Use `MARKDOWN_SMOKE_WINDOW_BOUNDS=x,y,width,height` and `MARKDOWN_SMOKE_WINDOW_FRAME_DEFAULT="x y w h sx sy sw sh "` only as explicit local overrides for unusual display setups.

Use examples:

- Smoke harness launch/window placement changes: `smoke-macos-launch-window.sh`.
- Navigation/search/outline/shortcut changes: `e2e-macos-navigation.sh`.
- New file, autosave, blank-file editing, rename changes: `e2e-macos-files.sh`.
- Live editor, formatting, copy/paste, list behavior, undo/redo changes: `e2e-macos-editing.sh`.
- Fenced-code marker/unwrapping changes: `e2e-macos-code-block-formatting.sh`.
- Image rendering and zoom changes: `e2e-macos-images.sh`.
- Filesystem watcher and selected-file churn changes: `e2e-macos-watch.sh`.

Run the fast smoke during normal iteration. Run the full E2E battery as a pre-commit/progress gate when the user asks to ship or record broad completed progress. Also run it earlier if a change touches shared app wiring, multiple feature surfaces, UI automation infrastructure, app launch/install behavior, or crash-prone WebView/AppKit bridge boundaries.

Pre-commit/progress gate for user-facing app changes:

```sh
./scripts/test-macos.sh
./scripts/build-macos-app.sh
./scripts/install-macos-app.sh
./scripts/smoke-macos-ui.sh
./scripts/e2e-macos-ui.sh
```

The UI smoke and E2E gates must fail if the app process exits unexpectedly or if a new `Markdown-*.ips` crash report appears during the run.

Manual QA should cover:

- light theme rendering
- keyboard navigation
- VoiceOver basics once UI exists
- window resizing and sidebar resizing
- multiple windows if supported

## Linting And Type Checking

Swift quality gates once the app exists:

```sh
xcodebuild test -scheme Markdown -destination 'platform=macOS'
swift test
swiftformat --lint .
swiftlint
```

Adapt command names to the actual project. Keep equivalent gates even if tools change.

If JavaScript or TypeScript tooling is added, use `pnpm` for package management and lockfiles.

Required TypeScript defaults:

- `strict: true`
- `noUncheckedIndexedAccess: true`
- schema validation at external boundaries
- no unchecked JSON parsing
- no direct `console.log` outside shared logging or test code

## Observability Standards

For a local macOS utility, logs should help diagnose failures without becoming noisy.

Log:

- app version
- opened file/folder URL redacted to safe display where appropriate
- file count and folder count for workspaces
- render duration
- file read errors
- renderer errors
- memory/performance warnings during spikes

Do not log:

- full document contents
- sensitive file paths in shared artifacts
- embedded image data
- private user notes

Use stable operation names such as:

- `workspace.open`
- `workspace.scan`
- `markdown.read`
- `markdown.render`
- `preview.display`

## Documentation Gate

Any change that affects product behavior, architecture, file handling, rendering semantics, performance assumptions, distribution, or user-visible workflow should update the relevant docs in the same change.

If docs are intentionally unchanged, the handoff should say why.

## Architecture Decision Gate

Use `docs/Architecture-Decisions.md` for decisions that should survive beyond one coding session.

The rendering-engine choice is accepted for MVP as WebView-backed preview rendering. Keep the renderer behind an adapter so it remains replaceable if production evidence changes the tradeoff.
