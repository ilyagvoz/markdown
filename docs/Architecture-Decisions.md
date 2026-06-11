# Architecture Decisions

This document records durable decisions. Pending decisions should stay explicit until a spike or implementation proves the right path.

## ADR 001: Build A Native macOS Markdown Reader

Status: accepted.

Decision: Build Markdown as a macOS app focused on opening and rendering local Markdown files and folders.

Context: The product goal is a fast, efficient, native-feeling Markdown renderer, like a simplified Obsidian without heavy knowledge-management features.

Consequences:

- The primary app target is macOS.
- Local file and folder workflows matter more than cloud or account workflows.
- Native macOS affordances are part of the product quality bar.
- Cross-platform support is not an MVP concern.

## ADR 002: Preview Mode By Default

Status: accepted.

Decision: Markdown files open in rendered preview mode by default.

Context: The app is a reader/renderer first, not a Markdown editor.

Consequences:

- The first implementation should optimize preview quality, file switching, and reading ergonomics.
- Editing is out of MVP unless explicitly reintroduced.
- Parser and renderer choices should be judged by reading performance and fidelity.

## ADR 003: Common Markdown Only For MVP

Status: accepted.

Decision: MVP supports common Markdown features and does not include Obsidian-specific syntax such as wiki links or backlinks.

Context: The user explicitly wants a simplified Obsidian-like app with none of the fancy features.

Consequences:

- No graph view, backlinks, plugins, Dataview, sync, or wiki-link semantics in MVP.
- Markdown fixtures should focus on common documents.
- Any dialect extension needs a future ADR.

## ADR 004: Use A Small Monorepo Shape

Status: accepted.

Decision: Use a small monorepo-style layout with `apps/macos`, `docs`, `spikes`, and future `packages` only when shared modules become useful.

Context: Distill's documentation and structure worked well for keeping product, architecture, and handoff context clear.

Consequences:

- Production app code should live under `apps/macos`.
- Spikes should stay under `spikes`.
- Docs should remain first-class project artifacts.
- The `packages` folder can remain absent until there is a real package boundary.

## ADR 005: Rendering Engine Choice

Status: accepted for MVP.

Decision: Use a WebView-backed preview renderer for the MVP. Markdown parsing/rendering should stay behind an adapter so the implementation can change later without rewriting workspace navigation.

Context: Spike 1 compared a native block-aware attributed-text prototype against a `WKWebView` prototype using the same `swift-markdown` parser. The native path was fast for small documents but required custom block layout to preserve Markdown structure, and the prototype slowed heavily on a 132 KB synthetic document. The WebView path preserved semantic HTML for headings, lists, code blocks, blockquotes, images, and tables with much lower large-document render time.

Consequences:

- Production preview should use `WKWebView` with local generated HTML and app-owned CSS.
- MVP preview styling should be light-only.
- CSS should explicitly control fonts, spacing, readable width, tables, code blocks, links, and the page palette.
- JavaScript should stay disabled unless a specific feature requires it.
- Parser and HTML generation should be isolated behind a renderer adapter.
- Native app navigation, file handling, commands, and sidebar should remain SwiftUI/AppKit-native.
- The native renderer can be revisited later if WebView selection, accessibility, memory, or styling behavior becomes a product problem.
- See `spikes/spike1-rendering-engine/RESULTS.md` for measurements.

## ADR 006: Light Mode Only For MVP

Status: accepted.

Decision: The MVP uses a light-only visual design.

Context: The desired product direction is a clean, joyful, highly readable Markdown reader. Earlier planning discussed native appearance, but the intended MVP direction is light mode only.

Consequences:

- The SwiftUI app should force Aqua/light appearance for the MVP.
- Generated preview HTML should use `color-scheme: light`.
- Dark mode support is a future feature, not part of the first polished MVP.
