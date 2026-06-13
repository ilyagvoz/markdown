# Release 0.1

Date: 2026-06-11

Markdown 0.1 is the first public MVP release: a native macOS Markdown reader and live-preview editor for local files and folders.

## Highlights

- Open individual `.md` / `.markdown` files or folder workspaces.
- Browse folder workspaces through a collapsible Markdown-only sidebar tree.
- Render common Markdown in a light, app-owned WebView preview.
- Edit in the rendered surface with save, autosave, undo/redo, lists, copy controls, and inline formatting.
- Search the current document, search the open workspace, and jump through a right-side document outline.
- Watch selected files and opened folders for external changes.

## Security Notes

- Raw HTML in Markdown files is rendered as text for 0.1.
- Clicked links open externally only for `http` and `https`.
- The downloadable 0.1 app is ad-hoc signed, but not Developer ID signed or notarized. macOS may ask for first-launch confirmation.

## Validation

Release validation should include:

```sh
./scripts/test-macos.sh
./scripts/build-macos-app.sh
./scripts/install-macos-app.sh
./scripts/smoke-macos-ui.sh
./scripts/e2e-macos-ui.sh
./scripts/profile-macos.sh spikes/spike1-rendering-engine/fixtures
```

The release artifact is `Markdown-0.1.0-macos-arm64.zip`.
