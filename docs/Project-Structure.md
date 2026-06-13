# Project Structure

This repository is named `markdown`.

The project is a small macOS-focused repo with production app code, durable docs, technical spikes, repeatable scripts, and generated artifacts. Shared packages should only be added when a real boundary is justified.

## Current Layout

```text
markdown/
├── README.md
├── AGENTS.md
├── docs/
│   ├── Architecture-Decisions.md
│   ├── Build-Plan.md
│   ├── Engineering-Standards.md
│   ├── Handoff.md
│   ├── Next-Steps.md
│   ├── Product-Design.md
│   ├── Progress.md
│   ├── Project-Structure.md
│   ├── Test-Coverage.md
│   └── Validation.md
│
├── apps/
│   └── macos/
│       └── Markdown/
│           ├── Package.swift
│           ├── Package.resolved
│           ├── Resources/
│           │   ├── AppIcon.icns
│           │   ├── AppIcon.iconset/
│           │   └── Info.plist
│           ├── Sources/
│           │   ├── MarkdownApp/
│           │   │   ├── AppModel.swift
│           │   │   ├── ContentView.swift
│           │   │   ├── DirectoryWatcher.swift
│           │   │   ├── FileWatcher.swift
│           │   │   ├── KeyboardShortcutMonitor.swift
│           │   │   ├── MarkdownApp.swift
│           │   │   ├── MarkdownEditorView.swift
│           │   │   ├── MarkdownWebPreview.swift
│           │   │   ├── PreviewAction.swift
│           │   │   └── ProcessResourceSampler.swift
│           │   ├── MarkdownAppSupport/
│           │   │   ├── AppSettings.swift
│           │   │   ├── MarkdownEditorHTML.swift
│           │   │   └── PreviewJavaScript.swift
│           │   └── MarkdownCore/
│           │       ├── MarkdownDocumentAnalyzer.swift
│           │       ├── MarkdownHTMLRenderer.swift
│           │       └── WorkspaceTree.swift
│           └── Tests/
│               ├── MarkdownAppSupportTests/
│               │   ├── AppSettingsTests.swift
│               │   ├── MarkdownEditorHTMLTests.swift
│               │   └── PreviewJavaScriptTests.swift
│               └── MarkdownCoreTests/
│                   ├── MarkdownDocumentAnalyzerTests.swift
│                   ├── MarkdownHTMLRendererTests.swift
│                   └── WorkspaceTreeBuilderTests.swift
│
├── scripts/
│   ├── build-macos-app.sh
│   ├── install-macos-app.sh
│   ├── profile-macos.sh
│   ├── run-macos.sh
│   ├── e2e-macos-ui.sh
│   ├── smoke-macos-ui.sh
│   ├── test-macos.sh
│   └── lib/
│       └── swift-env.sh
│
├── spikes/
│   ├── README.md
│   ├── spike1-rendering-engine/
│   │   ├── Package.swift
│   │   ├── Package.resolved
│   │   ├── README.md
│   │   ├── NOTES.md
│   │   ├── RESULTS.md
│   │   ├── Sources/
│   │   └── fixtures/
│   ├── spike2-editing-update-mode/
│   │   ├── Package.swift
│   │   ├── README.md
│   │   ├── RESULTS.md
│   │   ├── Sources/
│   │   └── Tests/
│   ├── spike3-candidate-a-webview-editor/
│   │   ├── README.md
│   │   ├── RESULTS.md
│   │   ├── tests/
│   │   └── web/
│   └── spike4-native-webview-editor/
│       ├── Package.swift
│       ├── README.md
│       ├── RESULTS.md
│       ├── Sources/
│       │   ├── NativeWebViewEditorSpike/
│       │   └── NativeWebViewEditorSpikeSupport/
│       ├── Tests/
│       └── scripts/
│
└── artifacts/
    ├── Markdown.app
    └── screenshots/
```

Generated build folders such as `.build/` and `apps/macos/Markdown/.build/` are intentionally omitted from the tree above.

## Ownership Boundaries

### `apps/macos/Markdown/Sources/MarkdownApp`

Owns the app shell, SwiftUI/AppKit UI, user intents, app model, WebView preview/editor integration, file watching, keyboard shortcuts, and resource sampling.

Rules:

- Keep SwiftUI views thin.
- Send user actions to `AppModel` or focused helpers.
- Keep parser-specific logic out of views.
- Keep WebView bridge behavior defensive and tested through support code where practical.

### `apps/macos/Markdown/Sources/MarkdownAppSupport`

Owns testable support code used by the app target but not tied to SwiftUI view rendering.

Current responsibilities:

- restored app settings and pane layout persistence
- live-preview editor HTML/script generation
- JavaScript string/script generation for preview actions

Rules:

- Prefer this target for deterministic app-support logic that should have fast unit tests.
- Keep public APIs small and boring.

### `apps/macos/Markdown/Sources/MarkdownCore`

Owns parser-adjacent and renderer-adjacent logic that should remain independent from the macOS UI.

Current responsibilities:

- workspace tree building and Markdown file filtering
- Markdown-to-HTML rendering adapter
- document outline and search analysis

Rules:

- Keep Common Markdown as the MVP boundary.
- Keep renderer decisions behind adapter-shaped APIs.
- Keep filesystem and Markdown behavior covered with unit tests.

### `apps/macos/Markdown/Tests`

Owns fast Swift unit tests.

Current test targets:

- `MarkdownCoreTests`
- `MarkdownAppSupportTests`

Rules:

- Add unit tests for deterministic logic.
- Add app-support tests for WebView bridge scripts, settings, formatting, and other crash-sensitive helpers.
- Use fast UI smoke for installed-app health and targeted UI E2E scripts for SwiftUI/AppKit/WebKit interaction boundaries.

### `docs`

Owns project memory and planning.

Rules:

- Start future sessions with `docs/Handoff.md`.
- Keep completed capabilities and lessons in `docs/Progress.md`.
- Keep `docs/Next-Steps.md` forward-looking.
- Use `docs/Architecture-Decisions.md` for durable choices.
- Update `docs/Validation.md` after meaningful test, profile, or screenshot passes.
- Update `docs/Test-Coverage.md` when user-facing behavior coverage changes.

### `scripts`

Owns repeatable local workflows.

Current scripts:

- `test-macos.sh` - run Swift tests.
- `build-macos-app.sh` - build release app bundle into `artifacts/Markdown.app`.
- `install-macos-app.sh` - install `/Applications/Markdown.app`.
- `update-to-latest-commit.sh` - fetch the latest GitHub commit, rebuild it in a temporary worktree, and install it locally.
- `run-macos.sh` - run the app against a file or folder.
- `smoke-macos-ui.sh` - fast installed-app health check for launch/open/search/edit/create/rename and crash-report checks.
- `smoke-macos-launch-window.sh` - narrow launch-window placement smoke check.
- `e2e-macos-ui.sh` - orchestrate the full installed-app UI regression battery.
- `e2e-macos-navigation.sh` - verify opening, search, outline, pane toggles, sidebar keyboarding, reveal, and open shortcuts.
- `e2e-macos-files.sh` - verify new-file creation, blank-file autosave, and rename.
- `e2e-macos-editing.sh` - verify live editing, list behavior, formatting, copy, undo/redo, and marker replacement.
- `e2e-macos-code-block-formatting.sh` - verify fenced-code marker unlock and unwrap behavior.
- `e2e-macos-images.sh` - verify rendered local Markdown images and image preview zoom controls.
- `e2e-macos-watch.sh` - verify folder watcher and selected-file churn survival.
- `profile-macos.sh` - profile release app CPU/RSS.
- `fixtures/` - deterministic source files copied into temporary smoke workspaces before mutation.

Rules:

- Prefer scripts over long one-off command sequences once a workflow is stable.
- Keep scripts safe to rerun.
- Keep shared SwiftPM environment setup in `scripts/lib/swift-env.sh`.

### `spikes`

Owns technical validation work.

Current spikes:

- `spike1-rendering-engine` - completed; recommends WebView-backed rendering for MVP.
- `spike2-editing-update-mode` - completed; recommends WebView-backed editing with app-owned Markdown serialization.
- `spike3-candidate-a-webview-editor` - completed; prototypes and tests the WebView editor model path from Spike 2.
- `spike4-native-webview-editor` - completed; proves the Candidate A editor model inside a native AppKit + `WKWebView` host with Swift bridge tests and native smoke validation.

Rules:

- Each spike should answer one risky question.
- Each spike should record criteria, observations, and recommendation.
- Do not promote spike code to production by accident.

### `artifacts`

Owns generated local outputs.

Current outputs:

- release app bundle
- screenshots
- profile logs or temporary validation artifacts as needed

Rules:

- Do not treat artifacts as source of truth.
- Reference useful screenshots from `docs/Validation.md`.

## Intentional Absences

There is no top-level `packages/` folder yet. Add it only when a shared boundary earns its keep.

There is no persistent database or search index. The product remains local-file-first and lightweight until measurement proves otherwise.

There is no plugin system, sync layer, graph view, or Obsidian-specific knowledge-management surface.
