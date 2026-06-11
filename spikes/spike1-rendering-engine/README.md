# Spike 1: Rendering Engine

## Question

Should Markdown render preview content with a native SwiftUI/AppKit renderer, or with a WebView-backed renderer?

## Why This Matters

The renderer choice affects the whole app:

- launch and file-switch performance
- memory usage
- scroll behavior
- text selection and copy behavior
- accessibility
- image handling
- code block styling
- future theming
- complexity of CommonMark compliance
- how native the app feels

This decision should be evidence-based before production code grows around it.

## Options To Compare

### Option A: Native SwiftUI/AppKit Rendering

Possible approaches:

- Swift Markdown parser plus native attributed text/layout.
- `AttributedString` rendering where feature coverage is sufficient.
- AppKit text views for better selection and scrolling control.

Hypothesis:

- Best native integration and potentially lower overhead.
- May require more work for Markdown fidelity, tables, code blocks, images, and layout edge cases.

### Option B: WebView-Backed Rendering

Possible approaches:

- Parse Markdown to HTML and display it in `WKWebView`.
- Use local CSS for typography and light/dark mode.
- Keep JavaScript disabled unless a specific need appears.

Hypothesis:

- Faster path to good Markdown fidelity and CSS-based styling.
- May cost more memory and feel less native for selection, scrolling, accessibility, and keyboard behavior.

## Required Fixtures

Create representative fixtures under `fixtures/`:

- `basic.md`: headings, paragraphs, emphasis, links.
- `lists.md`: nested ordered and unordered lists.
- `code.md`: inline code and fenced code blocks.
- `quotes.md`: blockquotes and horizontal rules.
- `images.md`: local image references, broken image reference.
- `tables.md`: table syntax if the parser supports it.
- `large.md`: generated large document for scroll and render timing.

## Measurements

Measure each option with the same fixtures:

- cold render time for small, medium, and large files
- file switch time across repeated fixture changes
- memory after opening one large file
- memory after switching files repeatedly
- scroll responsiveness on the large fixture
- CPU use during initial render and repeated switches
- visual fidelity against expected common Markdown behavior
- accessibility basics: selection, VoiceOver discoverability, keyboard focus

## Pass Criteria

The recommended path should:

- render common Markdown fixtures without crashes
- keep the UI responsive during large-file render and switching
- support text selection and copying cleanly
- support light/dark styling
- support local images or provide a clear implementation path
- preserve a native-feeling macOS reading experience
- avoid excessive implementation complexity for MVP

## Suggested Implementation

Keep this spike disposable.

Suggested shape:

```text
spikes/spike1-rendering-engine/
├── README.md
├── RESULTS.md
├── fixtures/
├── native-prototype/
└── webview-prototype/
```

Both prototypes should expose the same simple interaction:

- open fixture list
- select fixture
- render preview
- show timing/memory notes in debug output

## Results Template

Fill in `RESULTS.md` when complete:

```md
# Spike 1 Results

Status: passed / failed / inconclusive.

## Recommendation

...

## Measurements

...

## Native Prototype Notes

...

## WebView Prototype Notes

...

## Decision

Update ADR 005 with accepted / rejected / deferred.
```
