# Markdown

A fast, efficient, macOS-native Markdown renderer for reading local Markdown files and folders.

The product should feel like a simplified Obsidian focused on preview-first reading:

- Open individual Markdown files.
- Open folders as workspaces.
- Show folders and Markdown files in a navigable, collapsible tree.
- Render CommonMark-style Markdown by default in preview mode.
- Avoid plugin systems, backlinks, sync, graph views, databases, and other heavyweight note-app features.

## Documentation

| File | What it covers |
|---|---|
| [`docs/Product-Design.md`](docs/Product-Design.md) | Product vision, MVP scope, UX principles, and quality bar |
| [`docs/Engineering-Standards.md`](docs/Engineering-Standards.md) | Code quality, architecture, testing, performance, and docs rules |
| [`docs/Progress.md`](docs/Progress.md) | Completed capabilities, implementation lessons, and deferred product work |
| [`docs/Build-Plan.md`](docs/Build-Plan.md) | Initial architecture plan and sequencing |
| [`docs/Architecture-Decisions.md`](docs/Architecture-Decisions.md) | Durable decisions and pending ADRs |
| [`docs/Project-Structure.md`](docs/Project-Structure.md) | Intended repository layout and ownership boundaries |
| [`docs/Next-Steps.md`](docs/Next-Steps.md) | Forward-looking planning backlog |
| [`docs/Handoff.md`](docs/Handoff.md) | Minimal load order for future sessions |
| [`docs/Validation.md`](docs/Validation.md) | Latest build/test/screenshot validation notes |
| [`spikes/README.md`](spikes/README.md) | Technical spike index |

## Current Focus

The first polished MVP foundation is built under [`apps/macos/Markdown`](apps/macos/Markdown). It is a light-mode-only SwiftUI macOS app with WebView-backed Markdown preview, file/folder open flows, collapsible sidebar navigation, current-document and workspace search, a right-side outline, pane persistence, file watching, selected-file churn handling, and user-focused smoke coverage.

## Run It

Build and test:

```sh
./scripts/test-macos.sh
./scripts/build-macos-app.sh
```

Install into Applications:

```sh
./scripts/install-macos-app.sh
```

Run with a folder:

```sh
./scripts/run-macos.sh spikes/spike1-rendering-engine/fixtures
```

The release app bundle is generated at `artifacts/Markdown.app`. After install, launch it from `/Applications/Markdown.app`, Spotlight, or Launchpad.

## Validation

Latest verified gates:

- `./scripts/test-macos.sh` - 24 tests passing.
- `./scripts/build-macos-app.sh` - builds `artifacts/Markdown.app`.
- `./scripts/install-macos-app.sh` - installs `/Applications/Markdown.app`.
- `./scripts/smoke-macos-ui.sh` - drives installed-app file/folder, current/workspace search, outline, shortcut, watcher, and crash-report checks.
- `./scripts/profile-macos.sh spikes/spike1-rendering-engine/fixtures` - release app idles near 0% CPU and about 92-95 MB RSS after launch settles.
- Screenshot QA:
  - `artifacts/screenshots/markdown-next-06-final-fixtures.png` - final three-pane fixture flow.
  - `artifacts/screenshots/markdown-next-07-shortcuts-help.png` - keyboard shortcuts help.
  - `artifacts/screenshots/markdown-pane-persistence-invisible-dividers.png` - pane persistence build with invisible resize hit targets.

The first rendering spike recommends a WebView-backed preview for MVP, fed by a Markdown parser/HTML renderer behind an adapter. See [`spikes/spike1-rendering-engine/RESULTS.md`](spikes/spike1-rendering-engine/RESULTS.md).
