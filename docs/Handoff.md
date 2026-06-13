# Handoff

## Load Order

1. `README.md` - product summary and docs index.
2. `docs/Progress.md` - completed capabilities, implementation lessons, and deferred work.
3. `docs/Next-Steps.md` - forward-looking planning backlog.
4. `docs/Product-Design.md` - product scope and UX principles.
5. `docs/Engineering-Standards.md` - architecture, testing, performance, and docs rules.
6. `docs/Test-Coverage.md` - user-focused coverage matrix and required gates.
7. `docs/Architecture-Decisions.md` - accepted and pending decisions.
8. Focused spike or implementation docs for the task.

## Current Bias

- Use WebView-backed preview rendering for MVP, per Spike 1.
- Keep the MVP preview-first and common-Markdown-only.
- Keep MVP preview styling light-only and app-controlled through local CSS.
- Prefer native macOS workflows and responsiveness over feature breadth.
- Keep spike code separate from production app code.
- Add packages only when they earn their keep.

## First Commands

Pre-commit/progress gate:

```sh
./scripts/test-macos.sh
./scripts/build-macos-app.sh
./scripts/install-macos-app.sh
./scripts/smoke-macos-ui.sh
./scripts/e2e-macos-ui.sh
./scripts/profile-macos.sh spikes/spike1-rendering-engine/fixtures
```

For normal feature iteration, run `./scripts/test-macos.sh`, then `./scripts/smoke-macos-ui.sh` when you need a fast installed-app health check. If the change touches a specific UI surface, run only the targeted E2E regression slice for that surface:

```sh
./scripts/smoke-macos-launch-window.sh
./scripts/e2e-macos-navigation.sh
./scripts/e2e-macos-files.sh
./scripts/e2e-macos-editing.sh
./scripts/e2e-macos-code-block-formatting.sh
./scripts/e2e-macos-images.sh
./scripts/e2e-macos-watch.sh
```

Use `./scripts/smoke-macos-launch-window.sh` for launch placement/display regressions. It should only open the app and report the window bounds; do not use a feature E2E slice when the bug is simply where the window appears.

Use `./scripts/e2e-macos-ui.sh` as the full UI regression battery when the user asks to ship/record broad progress, or when a change is cross-cutting. `./scripts/smoke-macos-ui.sh` is intentionally small and should stay under roughly 30 seconds on a warm app/build.

Run the app against fixtures:

```sh
./scripts/run-macos.sh spikes/spike1-rendering-engine/fixtures
```

Run editing spike validation:

```sh
swift test --package-path spikes/spike2-editing-update-mode
node --test spikes/spike3-candidate-a-webview-editor/tests/*.test.mjs
spikes/spike4-native-webview-editor/scripts/smoke-native-editor.sh
```

See `docs/Validation.md` for the latest visual QA screenshots and notes.
