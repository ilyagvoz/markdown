# Repository Instructions

## JavaScript And TypeScript

- Use `pnpm` for package management and lockfiles in JavaScript/TypeScript projects.
- Use `pnpm add` / `pnpm add -D` for dependencies; avoid `npm` and `yarn` installs.
- Prefer TypeScript for new JavaScript ecosystem code.
- Use Bun only as a runtime/test/script tool when the project already supports it or when explicitly requested.
- Do not use `bun add` or `bun install` unless the repository is intentionally Bun-managed.

## Product Bias

- Build a fast, efficient, macOS-native Markdown reader.
- Render Markdown in preview mode by default.
- Use a light theme as the default and only supported theme for MVP.
- Support opening individual files and folders.
- For folders, show Markdown files and folders in a navigable, collapsible sidebar tree.
- MVP supports common Markdown only.
- Do not add Obsidian-style wiki links, backlinks, graph views, plugins, sync, or other heavy knowledge-management features unless a future decision explicitly adds them.

## Current Architecture Bias

- Use WebView-backed preview rendering for MVP, per Spike 1 and ADR 005.
- Keep Markdown parsing/rendering behind an adapter so the renderer remains replaceable.
- Keep preview styling app-owned through local CSS: fonts, spacing, width, tables, code, links, and light palette.
- Keep production code under `apps/macos` once the app exists.
- Keep risky experiments under `spikes`.
- Keep product and engineering context in `docs`.
- Add shared packages only when a real boundary is justified.

## Documentation

- Start new sessions with `docs/Handoff.md`.
- Use `docs/Next-Steps.md` for active work.
- Use `docs/Engineering-Standards.md` for build, test, performance, and documentation rules.
- Record durable architecture choices in `docs/Architecture-Decisions.md`.
