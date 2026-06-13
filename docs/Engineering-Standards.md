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
- File writes should stay limited to explicit local Markdown editing flows: selected-file saves, debounced autosave, and documented file actions such as create/rename.

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
- Sync or live collaborative editing.
- Custom Markdown dialects unless explicitly accepted through ADR.

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

`docs/Test-Coverage.md` is the canonical source for exact test commands and target-script selection. Keep these principles in sync with that file:

- Unit-test deterministic Swift, parser, workspace, and generated WebView/editor behavior first.
- Build and install before UI automation when the installed bundle must reflect current changes.
- Use the fast smoke for broad installed-app health.
- Use the narrowest targeted UI E2E script for the changed surface during iteration.
- Reserve the full UI E2E battery for shipping, broad progress records, cross-cutting app wiring, UI automation infrastructure, app launch/install behavior, and crash-prone WebView/AppKit bridge boundaries.
- UI smoke and E2E gates must fail if the app process exits unexpectedly or if a new `Markdown-*.ips` crash report appears during the run.

Manual QA should cover:

- light theme rendering
- keyboard navigation
- broader VoiceOver basics before distribution
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
