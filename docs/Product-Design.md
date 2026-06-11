# Product Design

## Product Vision

Markdown is a fast, focused macOS Markdown reader and live-preview editor. It should make local Markdown folders feel immediately readable and lightly editable without becoming a full knowledge-management system.

The app opens in preview mode by default. The main experience is a native-feeling three-part reading and editing workflow:

- Choose a file or folder.
- Navigate Markdown files from a collapsible sidebar tree.
- Read and lightly edit rendered Markdown quickly, comfortably, and predictably.

## Product Principles

- Preview-first reading, with lightweight live-preview editing.
- Local files are the source of truth.
- Common Markdown only for MVP.
- Fast launch, fast folder load, fast file switching.
- Native macOS behaviors where users expect them: file open panels, recent documents, keyboard navigation, window restoration, sidebar disclosure, drag resizing, accessibility, and system appearance.
- Avoid feature gravity. This is not Obsidian, Notion, Bear, or a wiki.

## Core User Experience

When the user opens a single Markdown file, the app displays the rendered document immediately.

When the user opens a folder, the app shows a left sidebar tree containing folders and Markdown files. Folders can be expanded and collapsed. Selecting a Markdown file renders it in the main pane.

When the user edits, the rendered surface should preserve the current line's presentation by default. Normal reading/editing view should hide Markdown block syntax so the document still feels rendered. Intentional type changes should be fast: moving to the start of a formatted line and pressing Left Arrow reveals and selects the Markdown marker for that line so it can be replaced immediately.

The app should preserve enough window and navigation state to feel calm between launches, but it should not build a separate library database or indexing system until evidence shows that is needed.

## MVP User Stories

- As a reader, I can open a `.md` or `.markdown` file and see rendered Markdown by default.
- As a reader, I can open a folder and browse nested folders and Markdown files from a collapsible tree.
- As a reader, I can switch between files without noticeable delay on normal local folders.
- As a reader, I can use keyboard navigation to move through the sidebar and open files.
- As a reader, I can use standard macOS open/recent-document workflows.
- As a reader, the app renders with a polished light theme and comfortable reading defaults.
- As an editor, I can make quick changes directly in the rendered document and save with `Cmd+S`.
- As an editor, I can undo and redo live-preview edits with standard macOS shortcuts.
- As an editor, I can create new Markdown blocks with `Return` and typed markers like `*`, `>`, or `#`.

## MVP Markdown Scope

Support common Markdown:

- headings
- paragraphs
- emphasis and strong emphasis
- inline code and fenced code blocks
- blockquotes
- ordered and unordered lists
- links
- images from local paths and remote URLs where the runtime safely supports them
- horizontal rules
- tables if the chosen parser/renderer supports them cleanly

Explicitly out of MVP:

- Obsidian wiki links
- backlinks
- graph view
- plugins
- sync
- live collaborative editing
- custom CSS themes
- embedded databases or query languages
- publishing

## Design Direction

The app should feel like a quiet macOS utility:

- Native sidebar and split-view proportions.
- High text readability over decoration.
- Compact, scannable file tree.
- Minimal toolbar.
- No landing page or marketing-style hero view.
- Clear empty states for no file, empty folder, unsupported file, and render failure.
- Light theme is the default and only supported theme for MVP.
- Preview typography should be app-owned and tuned for reading, not whatever a default WebView happens to use.
- Use local CSS to control preview fonts, line height, heading scale, paragraph/list spacing, code blocks, tables, link colors, and readable content width.
- Keep spacing fairly tight and document-dense while preserving comfortable line length.
- Use native system controls and sidebar styling around the preview.

## Performance Bar

The product promise is speed and efficiency.

Initial targets:

- Cold launch should feel immediate for the app shell.
- Opening a normal single Markdown file should render within one interaction beat.
- Opening a folder should populate the visible tree quickly and avoid blocking the UI on deep traversal.
- File switching should avoid full-app recomputation.
- Large files should remain scrollable and responsive.
- Rendering should not leak memory across repeated file switches.

Initial performance budgets should be refined during the macOS app skeleton after the WebView-backed renderer is integrated.

## Release Strategy

Recommended sequence:

1. Local developer build.
2. Private signed macOS app for personal daily use.
3. Harden file/folder handling with real folders.
4. Decide whether public distribution is worth pursuing after the MVP is useful.

## Quality Bar

MVP is ready when:

- Single-file open and folder-open flows work reliably.
- Sidebar tree is keyboard-accessible and handles nested folders.
- Common Markdown renders consistently across representative documents.
- Large documents and folders remain responsive.
- The app handles missing files, deleted files, unreadable files, empty folders, and broken image references gracefully.
- The rendering-engine decision has documented spike evidence.
