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

Start with:

```sh
./scripts/test-macos.sh
./scripts/build-macos-app.sh
./scripts/install-macos-app.sh
./scripts/smoke-macos-ui.sh
./scripts/profile-macos.sh spikes/spike1-rendering-engine/fixtures
```

For faster UI iteration, run the focused smoke script that matches the area being changed:

```sh
./scripts/smoke-macos-navigation.sh
./scripts/smoke-macos-files.sh
./scripts/smoke-macos-editing.sh
./scripts/smoke-macos-watch.sh
```

Use `./scripts/smoke-macos-ui.sh` as the full battery before calling a user-facing change complete.

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
