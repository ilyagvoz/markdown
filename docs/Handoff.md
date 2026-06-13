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

Use `docs/Test-Coverage.md` as the canonical test-selection guide. For ordinary Swift or app-support changes, start with:

```sh
./scripts/test-macos.sh
```

When installed-app behavior matters, build/install first, then run the fast smoke or the narrowest targeted E2E script named in `docs/Test-Coverage.md`. Use the full UI E2E battery only for shipping/progress gates or cross-cutting app wiring:

```sh
./scripts/build-macos-app.sh
./scripts/install-macos-app.sh
./scripts/smoke-macos-ui.sh
./scripts/e2e-macos-ui.sh
```

Use `./scripts/smoke-macos-launch-window.sh` for launch placement/display regressions. It should only open the app and report the window bounds; do not use a feature E2E slice when the bug is simply where the window appears.

Run the app against fixtures:

```sh
./scripts/run-macos.sh spikes/spike1-rendering-engine/fixtures
```

Run spike validation only when changing the relevant spike; commands are listed in `docs/Test-Coverage.md`.

See `docs/Validation.md` for latest gate results and `docs/Validation-History.md` for older smoke/crash notes.
