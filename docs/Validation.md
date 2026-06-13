# Validation

Last updated: 2026-06-13

## Automated Gates

Run:

```sh
./scripts/test-macos.sh
```

Latest result:

- Passed on 2026-06-13 in 0.20s test runtime on a warm cache.
- 41 unit tests.
- Coverage areas: Markdown HTML rendering, raw HTML escaping, light-only CSS contract, outline/landmark extraction, current-document search, workspace search result metadata/snippets, visible sidebar row navigation, selected-file replacement during workspace rebuilds, WebView JavaScript string/script generation, live-preview editor HTML/script generation including icon-only copy controls and link hover/activation bridge hooks, link destination resolution for local Markdown files, fragments, external URLs, unsupported schemes/files, code-block formatting and unwrap behavior, and tail-area append editing, default Markdown reader registration constants/errors, restored pane layout state, folder tree building, single-file workspace, unsupported file rejection, symbolic-link skipping.

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

Run:

```sh
./scripts/update-to-latest-commit.sh
```

Latest result:

- Passed on 2026-06-12.
- Resolved `origin/main` from GitHub, fetched commit `0532ee9`, built it in a temporary worktree, and installed `/Applications/Markdown.app`.

Fast installed-app smoke:

```sh
./scripts/smoke-macos-ui.sh
```

It covers launch, single-file open, folder open, current-document search, one edit/save path, new-file creation, rename, process health, and crash-report checks.

Latest fast-smoke result:

- Passed on 2026-06-13 in 12.9s.

Targeted UI E2E scripts tracked here:

```sh
./scripts/smoke-macos-launch-window.sh
./scripts/e2e-macos-navigation.sh
./scripts/e2e-macos-files.sh
./scripts/e2e-macos-editing.sh
./scripts/e2e-macos-code-block-formatting.sh
./scripts/e2e-macos-images.sh
./scripts/e2e-macos-watch.sh
```

Surface covered by each script:

- `smoke-macos-launch-window.sh` for smoke harness launch placement, display selection, and saved-window-frame behavior.
- `e2e-macos-navigation.sh` for opening, search, outline, pane toggles, sidebar keyboarding, and reveal.
- `e2e-macos-files.sh` for new-file creation, autosave from a blank file, and rename.
- `e2e-macos-editing.sh` for live-preview editing, list continuation/exit, blank-line editing, Markdown copy controls, formatting, undo/redo, and marker replacement.
- `e2e-macos-code-block-formatting.sh` for fenced-code Left Arrow unlock and unwrap behavior.
- `e2e-macos-images.sh` for rendered local Markdown images and full-window image preview zoom controls.
- `e2e-macos-watch.sh` for folder watcher add/delete and selected-file churn.

Latest code-block formatting result:

- Passed on 2026-06-13 in 18.5s.
- `e2e-macos-code-block-formatting.sh` opened a fenced Swift code block, used the Left Arrow marker-edit path, deleted the opening fence, saved, and verified the Markdown was unwrapped on disk.

Latest image rendering result:

- Passed on 2026-06-12.
- `e2e-macos-images.sh` opened a Markdown file with a relative local SVG image, opened the full-window preview, exercised zoom in, zoom out, reset, and close shortcuts, saved, and verified the image Markdown stayed unchanged.

Latest launch-window result:

- Passed.
- `smoke-macos-launch-window.sh` opened the app at `0 30 1299 848` on the built-in display after launching hidden and activating only after placement.

Latest navigation E2E result:

- Passed on 2026-06-13 in 23.8s after link-history shortcut monitor changes; opening, search, outline, pane toggles, sidebar keyboarding, reveal, and open shortcuts remained healthy.

Full UI E2E battery:

```sh
./scripts/e2e-macos-ui.sh
```

Latest result:

- Passed on 2026-06-13 in 164.1s before the final navigation relaunch consolidation; the changed navigation slice passed afterward as noted above.
- Orchestrates the targeted navigation, file, editing, code-block formatting, image, and watcher E2E scripts against the installed app.
- Drives `Cmd+O`, `Cmd+N`, `Cmd+F`, `Cmd+/`, `Cmd+S`, `Cmd+B`, `Cmd+I`, `Cmd+E`, `Cmd+K`, `Cmd+Control+H`, `Cmd+Up`, `Cmd+Down`, `Cmd+Left Arrow`, `Cmd+Right Arrow`, `Cmd+R`, plain sidebar arrows, `Space`, `Return`, outline clicks, current-document search-result clicks, workspace search-result clicks, folder-view file creation, native file rename prompt, debounced autosave, live-preview editing, Markdown copy buttons, selection formatting, fenced-code unwrap formatting, rendered image preview zoom controls, saved Markdown assertions, folder add/delete events, selected-file rename/delete, and final Markdown-file deletion.
- Fails if the app exits unexpectedly or a new `Markdown-*.ips` report appears.

See `docs/Test-Coverage.md` for the user-focused coverage matrix.

Run for the editing/update-mode spike:

```sh
swift test --package-path spikes/spike2-editing-update-mode
```

Latest result:

- Passed.
- 7 spike tests.
- Coverage areas: no-edit Markdown round-trip, heading/list/quote/fenced-code/code-content edits preserving presentation markers, and marker unlock behavior.

Run for the Candidate A WebView editor spike:

```sh
node --test spikes/spike3-candidate-a-webview-editor/tests/*.test.mjs
```

Latest result:

- Passed.
- 5 spike tests.
- Coverage areas: no-edit round-trip, marker-preserving visible edits, marker unlock, intentional presentation-type change from unlocked source, and native shortcut routing classification.

Run for the native Candidate A WebView editor spike:

```sh
spikes/spike4-native-webview-editor/scripts/smoke-native-editor.sh
```

Latest result:

- Passed.
- 4 Swift bridge tests plus native `WKWebView` smoke.
- Coverage areas: bridge message parsing/status text, native WebView resource load, marker-preserving visible edit, explicit unlock, marker preselection, intentional presentation-type change, unlocked line commit/re-render, and serialized Markdown verification from Swift.

Run:

```sh
./scripts/profile-macos.sh spikes/spike1-rendering-engine/fixtures
```

Latest release-profile result:

| Metric | Observation |
|---|---:|
| Settled idle CPU | 0.0-0.1% on later samples |
| Fixture settled RSS | about 92.1 MB after live-preview editor integration |
| Larger-folder settled RSS | about 116.6 MB against `~/dev/distill-v3/docs` |
| Launch/render RSS range | about 92.1-122.8 MB in the latest release-profile runs |
| Virtual size | very large, expected for modern macOS/WebKit process address space and not useful as real memory pressure |

In the managed Codex sandbox, SwiftPM may warn that user-level SwiftPM configuration/security paths under `~/Library` are not writable. The project scripts keep scratch space and caches inside the workspace; those warnings do not fail the gate.

## Manual / Visual QA

Previous QA screenshots were removed from repository history because they included desktop context. Future demo screenshots should be app-only captures and reviewed before publication.

Assessment:

- Function: single-file and folder-open flows work.
- Usability: sidebar hierarchy is clear, selected row is obvious, current/workspace search is discoverable, the outline panel is useful without overpowering the reading/editing surface, live-preview editing keeps block markers hidden until intentional marker editing, and status text remains unobtrusive.
- Joy: the light-only palette, warm paper reading surface, teal selection, calm three-pane layout, comfortable typography, restored preview-like document spacing, and new app icon are directionally right for daily use.

Link behavior:

- User manually verified link hover/open behavior in the native editor: `Cmd`/`Ctrl` click opens Markdown links in-app and external links in the browser, with in-app Back/Forward available afterward.
- Synthetic macOS modifier-click automation against contentEditable WebKit links was unreliable during implementation, so automated coverage is kept to deterministic resolver and generated bridge tests.

Known UX follow-ups:

- Add a first-run empty-state screenshot pass once final window sizing is settled.

## Detailed History

Older feature-smoke transcripts, spike validation notes, and crash investigations live in `docs/Validation-History.md`.
