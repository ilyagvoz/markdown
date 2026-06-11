# Security Review 0.1

Date: 2026-06-11

## Executive Summary

No critical or high-severity issues are known for the 0.1 release after this review. One medium WebView rendering issue was fixed before release: raw HTML in Markdown files is now rendered as text, and clicked links are constrained to external `http` / `https` opens.

The main remaining distribution risk is that the 0.1 downloadable app is only ad-hoc signed, not Developer ID signed or notarized. That is documented in the README and should be addressed before broader public distribution.

## Scope

Reviewed:

- Swift macOS app code under `apps/macos/Markdown/Sources`.
- Markdown rendering and WebView bridge paths.
- File/folder traversal and file write paths.
- Release scripts under `scripts`.
- Public docs and screenshots intended for GitHub.
- Repository text for obvious secrets or credentials.

Not reviewed:

- Apple Developer ID signing and notarization, because no Developer ID signing identity was available during this pass.
- Third-party dependency source code beyond dependency pinning and usage boundaries.

## Findings

### Critical

None.

### High

None.

### Medium

M-001: Raw HTML could execute inside preview WebViews. Fixed.

Impact: A malicious local Markdown file could embed raw HTML or script-like content that WebKit might execute because preview JavaScript is enabled for app search and outline behavior.

Evidence before fix:

- `apps/macos/Markdown/Sources/MarkdownCore/MarkdownHTMLRenderer.swift` rendered `swift-markdown` HTML directly.
- `apps/macos/Markdown/Sources/MarkdownApp/MarkdownWebPreview.swift` and `apps/macos/Markdown/Sources/MarkdownApp/MarkdownEditorView.swift` enable JavaScript for app-owned WebView behavior.

Fix:

- `MarkdownHTMLRenderer` now rewrites `HTMLBlock` and `InlineHTML` AST nodes into text before formatting at `apps/macos/Markdown/Sources/MarkdownCore/MarkdownHTMLRenderer.swift:21` and `apps/macos/Markdown/Sources/MarkdownCore/MarkdownHTMLRenderer.swift:323`.
- Preview and editor navigation delegates now cancel clicked WebView navigations after optionally opening `http` / `https` externally at `apps/macos/Markdown/Sources/MarkdownApp/MarkdownWebPreview.swift:88` and `apps/macos/Markdown/Sources/MarkdownApp/MarkdownEditorView.swift:134`.
- `MarkdownHTMLRendererTests.testRendersRawHTMLAsText` covers the raw HTML rendering behavior.

### Low

L-001: The 0.1 release artifact is not Developer ID signed or notarized.

Impact: Users may see a Gatekeeper prompt on first launch, and macOS cannot verify the app publisher through Developer ID.

Current handling:

- `scripts/build-macos-app.sh:24` ad-hoc signs the assembled `.app` bundle so resources are sealed and `codesign --verify --deep --strict` passes.
- README calls this out in the Download section.
- `docs/Next-Steps.md` tracks signing and notarization as distribution hardening.

Recommended follow-up:

- Add Developer ID signing, notarization, and release verification before a wider non-developer distribution push.

## Positive Checks

- File traversal skips hidden entries and symbolic links, which avoids accidental hidden-folder indexing and symlink cycles.
- Workspace scan failures are recorded per entry instead of crashing or failing the whole workspace.
- File writes are limited to the selected Markdown file in editing/save flows.
- JavaScript snippets generated from Swift use JSON string encoding for search and outline actions.
- Swift package dependencies are pinned in `Package.swift` / `Package.resolved`.
- No obvious secrets, private keys, API keys, or passwords were found in repository text during `rg` review.

## Release Recommendation

Release 0.1 is reasonable as an early, developer-facing macOS build with the ad-hoc-signed, non-notarized artifact caveat. Treat Developer ID signing, notarization, and broader accessibility validation as required before promoting it as a polished consumer download.
