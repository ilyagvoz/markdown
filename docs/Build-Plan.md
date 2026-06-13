# Build Plan

This is the historical condensed architecture plan for the first usable version. Current product status lives in `docs/Progress.md`, active follow-up work lives in `docs/Next-Steps.md`, and durable architecture changes live in `docs/Architecture-Decisions.md`.

## Decision

Build a private macOS Markdown reader that opens files and folders and renders Markdown in preview mode by default. Live-preview editing was later accepted through ADR 007 and shipped as part of the first production editor pass.

The first spike recommends a WebView-backed renderer for MVP. The rest of the architecture should still keep rendering behind an adapter:

- App shell owns windows, commands, and open/recent-document flows.
- Workspace model owns folder trees, expansion state, and selected files.
- Filesystem layer owns scanning, filtering, and file reads.
- Markdown layer owns parser/renderer adapters.
- Preview/editor layer displays rendered content and app-owned editing behavior.

## Architecture

```mermaid
graph TD
    A[macOS App Shell] --> B[Open File / Folder]
    B --> C[Workspace Tree]
    C --> D[Selected Markdown File]
    D --> E[Filesystem Reader]
    E --> F[Markdown Renderer Adapter]
    F --> G[Preview / Editor Pane]
    C --> H[Sidebar Tree]
```

## Initial Repository Shape

```text
markdown/
├── README.md
├── docs/
├── spikes/
├── apps/
│   └── macos/
└── packages/        # only when justified
```

## MVP Slices

### Slice 0: Rendering Engine Spike

Status: complete. Spike 1 recommends WebView-backed rendering for MVP.

Outcome:

- recommended renderer path: `WKWebView` with local generated HTML/CSS
- measured tradeoffs recorded in `spikes/spike1-rendering-engine/RESULTS.md`
- ADR 005 updated
- production implementation notes recorded in the spike

### Slice 1: App Skeleton

Status: complete for first MVP slice.

- Create macOS app target under `apps/macos`.
- Add app/window shell.
- Add empty, single-file, and folder-open states.
- Add basic diagnostics for render and file-open timings.

### Slice 2: Filesystem And Sidebar

Status: complete for first MVP slice.

- Open a folder.
- Build a collapsible tree of folders and `.md`/`.markdown` files.
- Ignore hidden/system noise by default.
- Select files and update preview state.
- Handle unreadable files without crashing.

### Slice 3: Markdown Preview

Status: complete for first MVP slice.

- Implement the WebView-backed renderer adapter.
- Generate semantic HTML from parsed Markdown.
- Load local HTML/CSS into `WKWebView`.
- Keep JavaScript limited to app-owned behavior that is explicitly justified.
- Force a light-only preview theme for MVP.
- Tune CSS for fonts, tighter spacing, readable width, links, tables, and code blocks.
- Render common Markdown fixtures.
- Support local images where safe.
- Add large-file smoke coverage.

### Slice 4: Native Polish

Status: complete for the reader MVP foundation; broader accessibility remains distribution hardening.

Complete:

- Light-only visual design.
- Screenshot-based visual QA for folder and single-file flows.
- Empty/error states.
- Unified open command.
- Recent files/folders.
- Last-open restoration.
- Selected-file live refresh.
- Folder-level file watching.
- Current-document search.
- Right-side document outline.
- Pane visibility and size persistence.
- App-level command-arrow routing.
- Keyboard shortcuts help.
- Lightweight CPU/RSS status readout.
- Release CPU/RSS profiling script.

Distribution follow-up:

- Broader accessibility pass before distribution.

### Slice 5: Live Preview Editing

Status: first production pass complete via ADR 007.

Complete:

- WebView-backed editable Markdown blocks.
- App-owned Markdown serialization.
- `Cmd+S` save and debounced autosave.
- Undo/redo, list continuation, marker replacement, formatting, Markdown copy controls, and rendered image blocks.

Remaining hardening lives in `docs/Next-Steps.md`.

## Non-Goals For MVP

- Obsidian wiki links/backlinks.
- Graph view.
- Plugins.
- Sync.
- Live collaborative editing.
- Persistent indexed search.
- Persistent library database.
- Publishing.

## Quality Gates

Before marking a slice complete:

- Relevant unit tests pass.
- Manual macOS smoke path is documented.
- Performance-sensitive changes include measurements or a note explaining why measurement was unnecessary.
- Docs are updated when behavior or architecture changes.
