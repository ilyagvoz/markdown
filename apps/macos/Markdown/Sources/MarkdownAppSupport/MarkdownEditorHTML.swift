import Foundation

public enum MarkdownEditorHTML {
    public static func document(markdown: String, title: String, baseURL: URL? = nil) -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
        \(baseElement(for: baseURL))
          <title>\(escapeHTML(title))</title>
          <style>
            :root {
              color-scheme: light;
              --page: #fbfaf6;
              --text: #24231f;
              --muted: #6d6a61;
              --rule: rgba(36, 35, 31, 0.14);
              --code-bg: #f1eee7;
              --quote: #3a6b68;
              --accent: #006b7a;
              --focus: rgba(0, 107, 122, 0.14);
              --focus-strong: rgba(0, 107, 122, 0.22);
              --highlight: rgba(255, 214, 102, 0.52);
              --table-stripe: rgba(0, 107, 122, 0.055);
            }

            html {
              background: var(--page);
              text-rendering: optimizeLegibility;
              -webkit-font-smoothing: antialiased;
            }

            body {
              margin: 0;
              padding: 46px 56px 78px;
              color: var(--text);
              background: var(--page);
              font-family: "New York", "Iowan Old Style", Charter, ui-serif, Georgia, serif;
              font-size: 18px;
              line-height: 1.72;
            }

            main {
              max-width: 780px;
              margin: 0 auto;
              min-height: calc(100vh - 124px);
            }

            .editor {
              min-height: calc(100vh - 124px);
            }

            .editor-block {
              display: block;
              margin: 0 0 1.05em;
            }

            .editor-marker {
              display: none;
            }

            .editor-content {
              min-height: 0;
              outline: none;
              border-radius: 7px;
              padding: 0;
              white-space: pre-wrap;
              overflow-wrap: anywhere;
            }

            .editor-content:focus {
              padding: 0.04em 0.2em;
              background: var(--focus);
              box-shadow: 0 0 0 2px var(--focus-strong);
            }

            .editor-content a {
              color: var(--accent);
              text-decoration-thickness: 0.08em;
              text-underline-offset: 0.18em;
            }

            .editor-content mark {
              border-radius: 4px;
              background: var(--highlight);
              padding: 0.02em 0.14em;
            }

            .formatting-menu {
              position: fixed;
              z-index: 20;
              display: flex;
              align-items: center;
              gap: 2px;
              padding: 4px;
              border: 1px solid rgba(36, 35, 31, 0.14);
              border-radius: 8px;
              background: rgba(251, 250, 246, 0.96);
              box-shadow: 0 10px 28px rgba(36, 35, 31, 0.16);
              backdrop-filter: blur(12px);
            }

            .formatting-menu[hidden] {
              display: none;
            }

            .formatting-menu button {
              min-width: 30px;
              height: 28px;
              border: 0;
              border-radius: 6px;
              color: var(--text);
              background: transparent;
              font: 700 13px -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            }

            .formatting-menu button:hover,
            .formatting-menu button:focus-visible {
              background: var(--focus);
              outline: none;
            }

            .formatting-menu [data-format="italic"] {
              font-style: italic;
            }

            .formatting-menu [data-format="highlight"] {
              background: var(--highlight);
            }

            .formatting-menu [data-format="code"] {
              font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
              font-weight: 800;
            }

            .formatting-menu [data-format="code-block"] {
              font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
              min-width: 38px;
            }

            .formatting-menu [data-format="link"] {
              min-width: 42px;
            }

            .copy-button {
              border: 1px solid rgba(36, 35, 31, 0.12);
              border-radius: 6px;
              color: var(--accent);
              background: rgba(251, 250, 246, 0.94);
              box-shadow: 0 6px 18px rgba(36, 35, 31, 0.10);
              display: inline-flex;
              align-items: center;
              justify-content: center;
              width: 32px;
              height: 32px;
              padding: 0;
              cursor: pointer;
            }

            .copy-button svg {
              width: 16px;
              height: 16px;
              stroke: currentColor;
              stroke-width: 2;
              stroke-linecap: round;
              stroke-linejoin: round;
              fill: none;
              pointer-events: none;
            }

            .copy-button:hover,
            .copy-button:focus-visible {
              background: var(--focus);
              outline: none;
            }

            .image-action-button {
              border: 1px solid rgba(36, 35, 31, 0.12);
              border-radius: 6px;
              color: var(--accent);
              background: rgba(251, 250, 246, 0.94);
              box-shadow: 0 6px 18px rgba(36, 35, 31, 0.10);
              display: inline-flex;
              align-items: center;
              justify-content: center;
              width: 34px;
              height: 34px;
              padding: 0;
              cursor: pointer;
            }

            .image-action-button svg {
              width: 17px;
              height: 17px;
              stroke: currentColor;
              stroke-width: 2;
              stroke-linecap: round;
              stroke-linejoin: round;
              fill: none;
              pointer-events: none;
            }

            .image-action-button:hover,
            .image-action-button:focus-visible {
              background: var(--focus);
              outline: none;
            }

            .document-copy-button {
              position: fixed;
              z-index: 12;
              top: 16px;
              right: 20px;
            }

            .editor-block-blank {
              height: 0;
              min-height: 0;
              margin: 0;
              overflow: hidden;
            }

            .editor-block-blank:focus-within {
              height: auto;
              min-height: 1.35em;
              margin-bottom: 1.05em;
              overflow: visible;
            }

            .editor-block-empty-document {
              height: auto;
              min-height: calc(100vh - 124px);
              margin-bottom: 1.05em;
              overflow: visible;
              cursor: text;
            }

            .editor-block-blank:focus-within .editor-content {
              min-height: 1.35em;
            }

            .editor-block-empty-document .editor-content {
              min-height: calc(100vh - 124px);
            }

            .editor-block-empty-document .editor-content:focus {
              background: linear-gradient(var(--focus), var(--focus)) left top / 100% 1.72em no-repeat;
              box-shadow: inset 0 0 0 2px transparent;
            }

            .editor-block-heading {
              margin: 1.65em 0 0.45em;
            }

            .editor-block-heading[data-level="1"] {
              margin-top: 0;
              margin-bottom: 0.62em;
            }

            .editor-block-heading[data-level="2"] {
              margin-top: 1.9em;
            }

            .editor-block-heading .editor-content {
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
              line-height: 1.18;
              color: var(--text);
              font-weight: 730;
            }

            .editor-block-heading[data-level="1"] .editor-content { font-size: 2.4rem; }
            .editor-block-heading[data-level="2"] .editor-content { font-size: 1.62rem; }
            .editor-block-heading[data-level="3"] .editor-content { font-size: 1.28rem; }
            .editor-block-heading[data-level="4"] .editor-content,
            .editor-block-heading[data-level="5"] .editor-content,
            .editor-block-heading[data-level="6"] .editor-content { font-size: 1.05rem; }

            .editor-block-unordered-list,
            .editor-block-ordered-list {
              margin: 0.18em 0 0.18em 1.08em;
            }

            .editor-block-paragraph:has(+ .editor-block-unordered-list),
            .editor-block-paragraph:has(+ .editor-block-ordered-list),
            .editor-block-paragraph:has(+ .editor-block-blank + .editor-block-unordered-list),
            .editor-block-paragraph:has(+ .editor-block-blank + .editor-block-ordered-list) {
              margin-bottom: 0.18em;
            }

            .editor-block-unordered-list .editor-content,
            .editor-block-ordered-list .editor-content {
              position: relative;
            }

            .editor-block-unordered-list .editor-content::before {
              content: "\\2022";
              position: absolute;
              left: -0.82em;
              color: var(--text);
            }

            .editor-block-ordered-list .editor-content::before {
              content: attr(data-marker-view);
              position: absolute;
              left: -1.38em;
              min-width: 1.05em;
              text-align: right;
              color: var(--text);
            }

            .editor-block-quote .editor-content {
              color: var(--muted);
              border-left: 4px solid var(--quote);
              padding-left: 1.05em;
            }

            .editor-block-image {
              margin: 1.2em 0 1.35em;
            }

            .editor-block-image .editor-content {
              outline: none;
            }

            .editor-block-image .editor-content:focus {
              padding: 0;
              background: transparent;
              box-shadow: 0 0 0 2px var(--focus-strong);
            }

            .editor-image-frame {
              position: relative;
              margin: 0;
              display: block;
            }

            .editor-image-frame img,
            .editor-inline-image {
              max-width: 100%;
              height: auto;
              border-radius: 8px;
              cursor: zoom-in;
            }

            .editor-image-frame img {
              display: block;
              box-shadow: 0 8px 24px rgba(31, 35, 40, 0.08);
            }

            .editor-image-frame .image-action-button {
              position: absolute;
              z-index: 8;
              top: 10px;
              right: 10px;
              opacity: 0;
              transition: opacity 120ms ease;
            }

            .editor-image-frame:hover .image-action-button,
            .editor-image-frame:focus-within .image-action-button,
            .editor-image-frame .image-action-button:focus-visible {
              opacity: 1;
            }

            .editor-image-fallback {
              border: 1px solid var(--rule);
              border-radius: 8px;
              padding: 0.85em 1em;
              color: var(--muted);
              background: rgba(36, 35, 31, 0.035);
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
              font-size: 0.92em;
              line-height: 1.45;
            }

            .editor-image-missing img {
              display: none;
            }

            .image-lightbox[hidden] {
              display: none;
            }

            .image-lightbox {
              position: fixed;
              inset: 0;
              z-index: 80;
              display: grid;
              grid-template-rows: auto 1fr;
              background: rgba(36, 35, 31, 0.84);
              color: #fbfaf6;
            }

            .image-lightbox-backdrop {
              position: absolute;
              inset: 0;
            }

            .image-lightbox-toolbar {
              position: relative;
              z-index: 2;
              display: flex;
              justify-content: flex-end;
              gap: 6px;
              padding: 14px 18px;
            }

            .image-lightbox-toolbar button {
              width: 36px;
              height: 36px;
              border: 1px solid rgba(251, 250, 246, 0.24);
              border-radius: 7px;
              color: #fbfaf6;
              background: rgba(251, 250, 246, 0.11);
              display: inline-flex;
              align-items: center;
              justify-content: center;
              padding: 0;
              cursor: pointer;
            }

            .image-lightbox-toolbar button:hover,
            .image-lightbox-toolbar button:focus-visible {
              background: rgba(251, 250, 246, 0.20);
              outline: none;
            }

            .image-lightbox-toolbar svg {
              width: 17px;
              height: 17px;
              stroke: currentColor;
              stroke-width: 2;
              stroke-linecap: round;
              stroke-linejoin: round;
              fill: none;
              pointer-events: none;
            }

            .image-lightbox-stage {
              position: relative;
              z-index: 1;
              min-width: 0;
              min-height: 0;
              display: flex;
              align-items: center;
              justify-content: center;
              overflow: hidden;
              padding: 0 28px 28px;
              cursor: grab;
            }

            .image-lightbox-stage:active {
              cursor: grabbing;
            }

            .image-lightbox-stage img {
              max-width: 100%;
              max-height: 100%;
              object-fit: contain;
              transform-origin: center center;
              will-change: transform;
              user-select: none;
              -webkit-user-drag: none;
              border-radius: 8px;
              box-shadow: 0 18px 70px rgba(0, 0, 0, 0.40);
            }

            .editor-table {
              width: 100%;
              margin: 0 0 1.05em;
              border-collapse: collapse;
              font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
              font-size: 0.92em;
              line-height: 1.45;
            }

            .editor-table th,
            .editor-table td {
              padding: 0.55em 0.7em;
              border-bottom: 1px solid var(--rule);
              vertical-align: top;
            }

            .editor-table th {
              text-align: left;
              font-weight: 680;
              color: var(--text);
            }

            .editor-table tbody tr:nth-child(odd) {
              background: var(--table-stripe);
            }

            .editor-table-cell {
              min-height: 1.45em;
              outline: none;
              border-radius: 5px;
              white-space: pre-wrap;
              overflow-wrap: anywhere;
            }

            .editor-table-cell:focus {
              padding: 0.04em 0.2em;
              background: var(--focus);
              box-shadow: 0 0 0 2px var(--focus-strong);
            }

            .editor-block-fence:not(.editor-block-unlocked) {
              display: none;
            }

            .editor-block-code {
              margin: 0;
            }

            .editor-block-code .editor-content,
            .editor-block-fence .editor-content {
              font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
              font-size: 0.88em;
              line-height: 1.55;
              background: var(--code-bg);
              border: 1px solid var(--rule);
            }

            .editor-block-code .editor-content {
              border-radius: 0;
              border-bottom-width: 0;
              padding-left: 1.1em;
              padding-right: 1.1em;
            }

            .editor-block-code:not(.editor-block-code-start) .editor-content {
              border-top-width: 0;
            }

            .editor-block-code-start {
              margin-top: 0.55em;
              position: relative;
            }

            .code-copy-button {
              position: absolute;
              z-index: 10;
              top: 8px;
              right: 8px;
            }

            .editor-block-code-end {
              margin-bottom: 1.2em;
            }

            .editor-block-code-start .editor-content {
              border-top-left-radius: 7px;
              border-top-right-radius: 7px;
              padding-top: 1em;
            }

            .editor-block-code-end .editor-content {
              border-bottom-width: 1px;
              border-bottom-left-radius: 7px;
              border-bottom-right-radius: 7px;
              padding-bottom: 1em;
            }

            .editor-block-fence .editor-content {
              color: var(--muted);
            }

            .editor-block-unlocked {
              margin: 0.18em 0 1.05em;
            }

            .editor-block-unlocked .editor-content::before {
              content: none;
            }

            .md-search-hit {
              border-radius: 4px;
              background: rgba(255, 214, 102, 0.58);
              box-shadow: 0 0 0 2px rgba(255, 214, 102, 0.32);
            }

            @media (max-width: 720px) {
              body {
                padding: 28px 24px 56px;
                font-size: 17px;
              }

              .editor-block-heading[data-level="1"] .editor-content { font-size: 2rem; }
              .editor-block-heading[data-level="2"] .editor-content { font-size: 1.45rem; }
            }
          </style>
        </head>
        <body>
          <button type="button" class="copy-button document-copy-button" data-copy-document aria-label="Copy document as Markdown" title="Click to copy">
            <svg aria-hidden="true" viewBox="0 0 24 24">
              <rect x="8" y="8" width="11" height="11" rx="2"></rect>
              <path d="M5 15H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v1"></path>
            </svg>
          </button>
          <main>
            <div class="editor" data-editor aria-label="Markdown live preview editor"></div>
          </main>
          <div class="formatting-menu" data-formatting-menu role="toolbar" aria-label="Formatting" hidden>
            <button type="button" data-format="bold" aria-label="Bold">B</button>
            <button type="button" data-format="italic" aria-label="Italic">I</button>
            <button type="button" data-format="highlight" aria-label="Highlight">H</button>
            <button type="button" data-format="code" aria-label="Inline code">`</button>
            <button type="button" data-format="link" aria-label="Link">Link</button>
            <button type="button" data-format="code-block" aria-label="Code block" title="Code block">&lt;/&gt;</button>
          </div>
          <div class="image-lightbox" data-image-lightbox role="dialog" aria-modal="true" aria-label="Image preview" hidden>
            <div class="image-lightbox-backdrop" data-image-lightbox-close></div>
            <div class="image-lightbox-toolbar" role="toolbar" aria-label="Image preview controls">
              <button type="button" data-image-zoom-out aria-label="Zoom out" title="Zoom out">
                <svg aria-hidden="true" viewBox="0 0 24 24"><circle cx="10" cy="10" r="6"></circle><path d="M15 15l5 5"></path><path d="M7 10h6"></path></svg>
              </button>
              <button type="button" data-image-zoom-in aria-label="Zoom in" title="Zoom in">
                <svg aria-hidden="true" viewBox="0 0 24 24"><circle cx="10" cy="10" r="6"></circle><path d="M15 15l5 5"></path><path d="M10 7v6"></path><path d="M7 10h6"></path></svg>
              </button>
              <button type="button" data-image-zoom-reset aria-label="Reset image zoom" title="Reset image zoom">
                <svg aria-hidden="true" viewBox="0 0 24 24"><path d="M4 9V4h5"></path><path d="M20 15v5h-5"></path><path d="M9 4 4 9"></path><path d="m15 20 5-5"></path></svg>
              </button>
              <button type="button" data-image-lightbox-close aria-label="Close image preview" title="Close">
                <svg aria-hidden="true" viewBox="0 0 24 24"><path d="M6 6l12 12"></path><path d="M18 6 6 18"></path></svg>
              </button>
            </div>
            <div class="image-lightbox-stage" data-image-lightbox-stage>
              <img data-image-lightbox-image alt="" draggable="false">
            </div>
          </div>
          <script>
            window.initialMarkdown = \(javaScriptString(markdown));
          </script>
          <script>
        \(editorScript)
          </script>
        </body>
        </html>
        """
    }

    private static func javaScriptString(_ value: String) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let encoded = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }
        return encoded
    }

    private static func escapeHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func baseElement(for url: URL?) -> String {
        guard let url else { return "" }
        return "  <base href=\"\(escapeHTML(url.absoluteString))\">"
    }

    private static let editorScript = #"""
(() => {
  let blocks = parseMarkdown(window.initialMarkdown || "");
  let pendingCommitTimer = null;
  let pendingMarkerSelection = null;
  let pendingUndoSnapshot = null;
  let activeTypingSnapshot = null;
  let lastTypingAt = 0;
  const maxHistoryDepth = 100;
  const undoStack = [];
  const redoStack = [];
  const editor = document.querySelector("[data-editor]");
  const formattingMenu = document.querySelector("[data-formatting-menu]");
  const copyDocumentButton = document.querySelector("[data-copy-document]");
  const imageLightbox = document.querySelector("[data-image-lightbox]");
  const imageLightboxImage = document.querySelector("[data-image-lightbox-image]");
  const imageLightboxStage = document.querySelector("[data-image-lightbox-stage]");
  const copyIconSVG = `<svg aria-hidden="true" viewBox="0 0 24 24"><rect x="8" y="8" width="11" height="11" rx="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v1"></path></svg>`;
  const copiedIconSVG = `<svg aria-hidden="true" viewBox="0 0 24 24"><path d="M20 6 9 17l-5-5"></path></svg>`;
  const zoomIconSVG = `<svg aria-hidden="true" viewBox="0 0 24 24"><circle cx="10" cy="10" r="6"></circle><path d="M15 15l5 5"></path><path d="M10 7v6"></path><path d="M7 10h6"></path></svg>`;
  let imageLightboxState = { scale: 1, x: 0, y: 0, dragging: false, dragX: 0, dragY: 0, startX: 0, startY: 0, returnFocus: null };
  let lastFormattingSelection = null;

  render();
  post("ready");
  installFormattingMenu();
  installCopyControls();
  installImageInteractions();
  installBlankDocumentClickTarget();
  installLinkInteractions();

  window.markdownClearSearchHighlights = function() {
    document.querySelectorAll(".md-search-hit").forEach(function(node) {
      const parent = node.parentNode;
      while (node.firstChild) parent.insertBefore(node.firstChild, node);
      parent.removeChild(node);
      parent.normalize();
    });
  };

  window.markdownJumpTo = function(id) {
    const target = document.getElementById(id);
    if (!target) return false;
    target.scrollIntoView({ block: "start", behavior: "smooth" });
    return true;
  };

  window.markdownFindText = function(query, occurrence) {
    window.markdownClearSearchHighlights();
    if (!query) return false;
    const needle = query.toLocaleLowerCase();
    const walker = document.createTreeWalker(editor, NodeFilter.SHOW_TEXT);
    let node;
    let index = 0;
    while ((node = walker.nextNode())) {
      const haystack = node.nodeValue.toLocaleLowerCase();
      const found = haystack.indexOf(needle);
      if (found === -1) continue;
      if (index !== occurrence) {
        index += 1;
        continue;
      }
      const range = document.createRange();
      range.setStart(node, found);
      range.setEnd(node, found + query.length);
      const mark = document.createElement("mark");
      mark.className = "md-search-hit";
      range.surroundContents(mark);
      mark.scrollIntoView({ block: "center", behavior: "smooth" });
      return true;
    }
    return false;
  };

  function installFormattingMenu() {
    document.addEventListener("selectionchange", () => {
      window.requestAnimationFrame(updateFormattingMenu);
    });
    window.addEventListener("resize", hideFormattingMenu);
    window.addEventListener("scroll", hideFormattingMenu, true);

    formattingMenu?.addEventListener("mousedown", (event) => {
      event.preventDefault();
    });

    formattingMenu?.addEventListener("click", (event) => {
      const button = event.target.closest("button[data-format]");
      if (!button) return;
      event.preventDefault();
      applyFormatting(button.dataset.format);
    });
  }

  function installBlankDocumentClickTarget() {
    document.addEventListener("click", (event) => {
      if (shouldIgnoreAppendTarget(event.target)) return;
      const emptyRow = editor.querySelector(".editor-block-empty-document");
      if (emptyRow) {
        const content = emptyRow.querySelector(".editor-content");
        if (!content) return;
        content.focus();
        moveCaretToEnd(content);
        return;
      }

      if (!isTailAppendClick(event)) return;
      event.preventDefault();
      appendBlockAtEnd();
    });

    document.addEventListener("keydown", (event) => {
      if (!shouldAppendFromDocumentKeydown(event)) return;
      event.preventDefault();
      appendBlockAtEnd(normalizedKey(event.key) === "Enter" ? "" : event.key);
    });
  }

  function installLinkInteractions() {
    let hoveredLink = null;
    let lastActivation = { href: "", at: 0 };

    editor.addEventListener("mouseover", (event) => {
      const link = closestLink(event.target);
      if (!link || !editor.contains(link)) return;
      const payload = linkPayload(link);
      link.setAttribute("title", payload.resolvedHref || payload.href);
      if (hoveredLink === link) return;
      hoveredLink = link;
      post("linkHovered", payload, false);
    });

    editor.addEventListener("mouseout", (event) => {
      const link = closestLink(event.target);
      if (!link || !editor.contains(link)) return;
      if (event.relatedTarget && link.contains(event.relatedTarget)) return;
      if (hoveredLink === link) hoveredLink = null;
      post("linkHoverEnded", {}, false);
    });

    editor.addEventListener("mousedown", (event) => {
      const link = closestLink(event.target);
      if (!link || !editor.contains(link)) return;
      if (hasLinkOpenModifier(event)) activateLink(link, event, lastActivation);
    }, true);

    editor.addEventListener("click", (event) => {
      const link = closestLink(event.target);
      if (!link || !editor.contains(link)) return;
      event.preventDefault();
      if (!hasLinkOpenModifier(event)) return;
      activateLink(link, event, lastActivation);
    });

    editor.addEventListener("contextmenu", (event) => {
      const link = closestLink(event.target);
      if (!link || !editor.contains(link) || !event.ctrlKey) return;
      activateLink(link, event, lastActivation);
    }, true);
  }

  function installCopyControls() {
    copyDocumentButton?.addEventListener("mousedown", (event) => {
      event.preventDefault();
    });
    copyDocumentButton?.addEventListener("click", (event) => {
      event.preventDefault();
      requestMarkdownCopy("document", serializeBlocks(blocks), copyDocumentButton);
    });

    editor.addEventListener("mousedown", (event) => {
      if (event.target.closest?.("[data-copy-code]")) event.preventDefault();
    });
    editor.addEventListener("click", (event) => {
      const button = event.target.closest?.("[data-copy-code]");
      if (!button) return;
      event.preventDefault();
      const markdown = codeSectionMarkdown(button.dataset.blockId);
      requestMarkdownCopy("code", markdown, button);
    });
  }

  function render(focusID = null, selectionRange = null, caretEnd = false, caretOffset = null) {
    hideFormattingMenu();
    editor.innerHTML = "";
    blocks = reindexBlocks(blocks);

    for (let index = 0; index < blocks.length; index += 1) {
      const tableGroup = tableGroupAt(index);
      if (tableGroup) {
        renderTableGroup(tableGroup);
        index = tableGroup.end;
        continue;
      }

      const block = blocks[index];
      const row = document.createElement("div");
      row.className = `editor-block editor-block-${block.type}`;
      if (block.unlocked) row.classList.add("editor-block-unlocked");
      if (block.type === "blank" && blocks.length === 1) row.classList.add("editor-block-empty-document");
      if (block.type === "code") {
        const previous = blocks[block.index - 1];
        const next = blocks[block.index + 1];
        if (previous?.type !== "code") row.classList.add("editor-block-code-start");
        if (next?.type !== "code") row.classList.add("editor-block-code-end");
      }
      row.dataset.blockId = block.id;
      row.dataset.type = block.type;
      row.dataset.level = String(block.level || 0);
      if (block.anchorID) row.id = block.anchorID;

      const marker = document.createElement("span");
      marker.className = "editor-marker";
      marker.textContent = markerText(block);

      const content = document.createElement("div");
      content.className = "editor-content";
      if (block.type === "image" && !block.unlocked) content.classList.add("editor-image-content");
      content.contentEditable = block.type === "image" && !block.unlocked ? "false" : "true";
      if (block.type === "image" && !block.unlocked) content.tabIndex = 0;
      content.spellcheck = true;
      content.dataset.raw = block.visibleText;
      content.dataset.markerView = markerViewText(block);
      renderBlockContent(content, block);
      content.setAttribute("aria-label", block.type === "image" ? `image line ${block.index + 1}: ${block.alt || "Image"}` : `${block.type} line ${block.index + 1}`);

      content.addEventListener("focus", () => {
        if (block.unlocked || isRawDisplayType(block) || block.type === "image") return;
        const currentText = content.textContent;
        content.textContent = block.visibleText;
        if (currentText === block.visibleText) return;
        moveCaretToEnd(content);
      });

      content.addEventListener("beforeinput", (event) => {
        captureUndoSnapshot(block.id, event);
      });

      content.addEventListener("input", () => {
        recordUndoSnapshot();
        const rawText = content.textContent;
        if (block.unlocked) {
          blocks = updateUnlockedDraft(blocks, block.id, rawText);
          scheduleUnlockedCommit(block.id);
        } else if (shouldPromoteBlankTypedText(block, rawText)) {
          blocks = replaceBlockWithSource(blocks, block.id, rawText);
        } else if (shouldParseTypedSource(block, rawText) || shouldReplaceFormattedTypedSource(block, rawText)) {
          blocks = replaceBlockWithSource(blocks, block.id, rawText);
          render(block.id, null, true);
        } else {
          blocks = editVisibleText(blocks, block.id, rawText);
        }
        post("documentChanged");
      });

      content.addEventListener("keydown", (event) => {
        const route = classifyShortcut(event);
        if (route === "save") {
          event.preventDefault();
          post("saveRequested", { key: event.key, route });
          return;
        }
        if (route === "undo") {
          event.preventDefault();
          undo();
          return;
        }
        if (route === "redo") {
          event.preventDefault();
          redo();
          return;
        }
        if (route.startsWith("format-")) {
          event.preventDefault();
          const format = route.replace("format-", "");
          applyFormatting(format);
          return;
        }
        if (route !== "editor") {
          post("shortcut", { key: event.key, route });
          return;
        }

        if (!block.unlocked && shouldDeleteEmptyCodeLine(block, event)) {
          event.preventDefault();
          recordUndoSnapshot(makeHistorySnapshot(block.id));
          resetTypingSnapshot();
          const focus = deleteEmptyCodeLine(block.id, normalizedKey(event.key));
          render(focus.id, null, focus.caretEnd);
          post("documentChanged", { formatting: "delete-empty-code-line" });
          return;
        }

        if (block.unlocked && pendingMarkerSelection?.id === block.id && isMarkerReplacementKey(event)) {
          event.preventDefault();
          recordUndoSnapshot(makeHistorySnapshot(block.id));
          resetTypingSnapshot();
          const replacement = event.key === "Backspace" || event.key === "Delete" ? "" : event.key;
          if (pendingMarkerSelection.unwrapCodeBlock && replacement === "") {
            const focusIndex = codeSectionRange(blocks, block.id)?.start || block.index;
            blocks = unwrapCodeBlock(blocks, block.id);
            pendingMarkerSelection = null;
            const focusBlock = blocks[Math.min(focusIndex, blocks.length - 1)];
            render(focusBlock?.id || null, null, false, 0);
            post("documentChanged", { formatting: "unwrap-code-block" });
            return;
          }
          replaceRangeInContent(content, pendingMarkerSelection.start, pendingMarkerSelection.end, replacement);
          pendingMarkerSelection = null;
          blocks = updateUnlockedDraft(blocks, block.id, content.textContent);
          scheduleUnlockedCommit(block.id);
          post("documentChanged");
          return;
        }

        if (block.unlocked && normalizedKey(event.key) === "Enter") {
          event.preventDefault();
          recordUndoSnapshot(makeHistorySnapshot(block.id));
          resetTypingSnapshot();
          clearPendingMarkerSelection();
          blocks = commitUnlockedSource(blocks, block.id, true);
          render(block.id, null, true);
          post("documentChanged");
          return;
        }

        if (!block.unlocked && block.type === "image" && (normalizedKey(event.key) === "Enter" || normalizedKey(event.key) === " ")) {
          event.preventDefault();
          openImageLightbox(block.destination, block.alt || "", block.title || "", content);
          return;
        }

        if (!block.unlocked && normalizedKey(event.key) === "Enter") {
          event.preventDefault();
          recordUndoSnapshot(makeHistorySnapshot(block.id));
          resetTypingSnapshot();
          const nextID = splitBlockAtCaret(block.id, currentCaretOffset());
          render(nextID, null, true);
          post("documentChanged");
          return;
        }

        const caretOffset = block.type === "image" && !block.unlocked ? 0 : currentCaretOffset();
        if (!block.unlocked && shouldUnlockFromKey(event, caretOffset)) {
          const unlockTarget = markerUnlockTarget(block);
          event.preventDefault();
          blocks = unlockTarget.unlock(blocks);
          render(unlockTarget.focusID, unlockTarget.selectionRange);
          if (unlockTarget.documentChanged) {
            post("documentChanged", { formatting: unlockTarget.documentChanged });
            return;
          }
          post("blockUnlocked", { blockID: unlockTarget.focusID });
        }
      });

      content.addEventListener("blur", () => {
        clearPendingCommit();
        clearPendingMarkerSelection();
        const current = findBlock(block.id);
        if (current?.unlocked) {
          blocks = commitUnlockedSource(blocks, block.id, true);
        }
        render();
        post("documentChanged");
      });

      row.append(marker, content);
      if (block.type === "code" && row.classList.contains("editor-block-code-start")) {
        const copyButton = document.createElement("button");
        copyButton.type = "button";
        copyButton.className = "copy-button code-copy-button";
        copyButton.dataset.copyCode = "true";
        copyButton.dataset.blockId = block.id;
        copyButton.setAttribute("aria-label", `Copy code section starting at line ${block.index + 1} as Markdown`);
        copyButton.setAttribute("title", "Click to copy");
        copyButton.innerHTML = copyIconSVG;
        row.append(copyButton);
      }
      editor.append(row);
    }

    if (focusID) {
      const target = editor.querySelector(`[data-block-id="${focusID}"] .editor-content, [data-block-id="${focusID}"] .editor-table-cell`);
      target?.focus();
      if (selectionRange) {
        pendingMarkerSelection = { id: focusID, ...selectionRange };
        setTextSelection(target, selectionRange.start, selectionRange.end);
        window.setTimeout(() => {
          if (pendingMarkerSelection?.id === focusID) {
            target?.focus();
            setTextSelection(target, selectionRange.start, selectionRange.end);
          }
        }, 0);
      } else if (caretOffset !== null) {
        clearPendingMarkerSelection();
        setTextSelection(target, caretOffset, caretOffset);
      } else if (caretEnd) {
        moveCaretToEnd(target);
      } else {
        clearPendingMarkerSelection();
        moveCaretToStart(target);
      }
    }
  }

  function tableGroupAt(index) {
    const header = blocks[index];
    const separator = blocks[index + 1];
    if (header?.type !== "table-header" || separator?.type !== "table-separator") return null;

    const rows = [];
    let cursor = index + 2;
    while (blocks[cursor]?.type === "table-row") {
      rows.push(blocks[cursor]);
      cursor += 1;
    }

    return {
      header,
      separator,
      rows,
      alignments: separator.alignments || header.alignments || [],
      end: cursor - 1,
    };
  }

  function renderTableGroup(group) {
    const table = document.createElement("table");
    table.className = "editor-table";
    table.dataset.blockId = group.header.id;
    table.dataset.type = "table";

    const thead = document.createElement("thead");
    const headerRow = document.createElement("tr");
    headerRow.dataset.blockId = group.header.id;
    group.header.cells.forEach((cell, cellIndex) => {
      headerRow.append(tableCellElement("th", group.header, cellIndex, cell, group.alignments[cellIndex]));
    });
    thead.append(headerRow);
    table.append(thead);

    const tbody = document.createElement("tbody");
    group.rows.forEach((rowBlock) => {
      const row = document.createElement("tr");
      row.dataset.blockId = rowBlock.id;
      normalizedTableCells(rowBlock, group.header.cells.length).forEach((cell, cellIndex) => {
        row.append(tableCellElement("td", rowBlock, cellIndex, cell, group.alignments[cellIndex]));
      });
      tbody.append(row);
    });
    table.append(tbody);
    editor.append(table);
  }

  function tableCellElement(tag, block, cellIndex, value, alignment) {
    const cell = document.createElement(tag);
    if (alignment) cell.style.textAlign = alignment;

    const content = document.createElement("div");
    content.className = "editor-table-cell";
    content.contentEditable = "true";
    content.spellcheck = true;
    content.dataset.raw = value;
    content.dataset.cellIndex = String(cellIndex);
    content.innerHTML = inlineMarkdownHTML(value);
    content.setAttribute("aria-label", `${block.type} line ${block.index + 1} cell ${cellIndex + 1}`);

    content.addEventListener("focus", () => {
      const currentText = content.textContent;
      content.textContent = tableCellValue(block.id, cellIndex);
      if (currentText !== content.textContent) moveCaretToEnd(content);
    });

    content.addEventListener("beforeinput", (event) => {
      captureUndoSnapshot(block.id, event);
    });

    content.addEventListener("input", () => {
      recordUndoSnapshot();
      blocks = updateTableCell(blocks, block.id, cellIndex, content.textContent);
      post("documentChanged");
    });

    content.addEventListener("keydown", (event) => {
      const route = classifyShortcut(event);
      if (route === "save") {
        event.preventDefault();
        post("saveRequested", { key: event.key, route });
        return;
      }
      if (route === "undo") {
        event.preventDefault();
        undo();
        return;
      }
      if (route === "redo") {
        event.preventDefault();
        redo();
        return;
      }
      if (route !== "editor") {
        post("shortcut", { key: event.key, route });
        return;
      }
      if (normalizedKey(event.key) === "Enter") {
        event.preventDefault();
      }
    });

    content.addEventListener("blur", () => {
      render();
      post("documentChanged");
    });

    cell.append(content);
    return cell;
  }

  function tableCellValue(blockID, cellIndex) {
    const block = findBlock(blockID);
    return normalizedTableCells(block, cellIndex + 1)[cellIndex] || "";
  }

  function normalizedTableCells(block, minimumCount) {
    const cells = [...(block?.cells || parseTableRow(block?.source || ""))];
    while (cells.length < minimumCount) cells.push("");
    return cells;
  }

  function updateTableCell(sourceBlocks, id, cellIndex, value) {
    return sourceBlocks.map((block) => {
      if (block.id !== id || !isTableBlock(block)) return block;
      const cells = normalizedTableCells(block, cellIndex + 1);
      cells[cellIndex] = value.replace(/\n/g, " ");
      const source = tableRowSource(cells);
      return { ...block, cells, source, visibleText: source };
    });
  }

  function tableRowSource(cells) {
    return `| ${cells.map((cell) => cell.trim()).join(" | ")} |`;
  }

  function post(type, payload = {}, includeMarkdown = true) {
    const message = {
      type,
      ...payload,
    };
    if (includeMarkdown) message.markdown = serializeBlocks(blocks);
    window.webkit?.messageHandlers?.editor?.postMessage(message);
  }

  function requestMarkdownCopy(kind, markdown, button) {
    window.webkit?.messageHandlers?.editor?.postMessage({
      type: "copyRequested",
      copyKind: kind,
      copyMarkdown: markdown,
    });
    showCopiedState(button);
  }

  function showCopiedState(button) {
    if (!button) return;
    button.innerHTML = copiedIconSVG;
    button.setAttribute("title", "Copied");
    window.setTimeout(() => {
      button.innerHTML = copyIconSVG;
      button.setAttribute("title", "Click to copy");
    }, 1100);
  }

  function installImageInteractions() {
    editor.addEventListener("mousedown", (event) => {
      if (event.target.closest?.("[data-image-preview], [data-open-image]")) event.preventDefault();
    });

    editor.addEventListener("click", (event) => {
      const target = event.target.closest?.("[data-image-preview], [data-open-image]");
      if (!target) return;
      event.preventDefault();
      openImageLightbox(target.dataset.imageSrc, target.dataset.imageAlt || "", target.dataset.imageTitle || "", target);
    });

    imageLightbox?.addEventListener("click", (event) => {
      if (!event.target.closest?.("[data-image-lightbox-close]")) return;
      event.preventDefault();
      closeImageLightbox();
    });

    imageLightbox?.querySelector("[data-image-zoom-in]")?.addEventListener("click", () => zoomImageLightbox(1.25));
    imageLightbox?.querySelector("[data-image-zoom-out]")?.addEventListener("click", () => zoomImageLightbox(0.8));
    imageLightbox?.querySelector("[data-image-zoom-reset]")?.addEventListener("click", resetImageLightboxZoom);

    imageLightboxStage?.addEventListener("wheel", (event) => {
      if (imageLightbox?.hidden) return;
      event.preventDefault();
      zoomImageLightbox(event.deltaY < 0 ? 1.12 : 0.9);
    }, { passive: false });

    imageLightboxStage?.addEventListener("pointerdown", (event) => {
      if (imageLightbox?.hidden) return;
      imageLightboxState.dragging = true;
      imageLightboxState.dragX = event.clientX;
      imageLightboxState.dragY = event.clientY;
      imageLightboxState.startX = imageLightboxState.x;
      imageLightboxState.startY = imageLightboxState.y;
      imageLightboxStage.setPointerCapture?.(event.pointerId);
    });

    imageLightboxStage?.addEventListener("pointermove", (event) => {
      if (!imageLightboxState.dragging) return;
      imageLightboxState.x = imageLightboxState.startX + event.clientX - imageLightboxState.dragX;
      imageLightboxState.y = imageLightboxState.startY + event.clientY - imageLightboxState.dragY;
      updateImageLightboxTransform();
    });

    imageLightboxStage?.addEventListener("pointerup", (event) => {
      imageLightboxState.dragging = false;
      imageLightboxStage.releasePointerCapture?.(event.pointerId);
    });

    document.addEventListener("keydown", (event) => {
      if (imageLightbox?.hidden) return;
      if (event.key === "Escape") {
        event.preventDefault();
        closeImageLightbox();
      } else if (event.key === "+" || event.key === "=") {
        event.preventDefault();
        zoomImageLightbox(1.25);
      } else if (event.key === "-") {
        event.preventDefault();
        zoomImageLightbox(0.8);
      } else if (event.key === "0") {
        event.preventDefault();
        resetImageLightboxZoom();
      }
    });
  }

  function openImageLightbox(src, alt, title, returnFocus) {
    const safeSrc = safeImageURL(src);
    if (!safeSrc || !imageLightbox || !imageLightboxImage) return;
    imageLightboxState = { scale: 1, x: 0, y: 0, dragging: false, dragX: 0, dragY: 0, startX: 0, startY: 0, returnFocus };
    imageLightboxImage.src = safeSrc;
    imageLightboxImage.alt = alt || title || "Image";
    if (title) imageLightboxImage.title = title;
    else imageLightboxImage.removeAttribute("title");
    imageLightbox.hidden = false;
    updateImageLightboxTransform();
    imageLightbox.querySelector("[data-image-zoom-in]")?.focus();
  }

  function closeImageLightbox() {
    if (!imageLightbox || !imageLightboxImage) return;
    imageLightbox.hidden = true;
    imageLightboxImage.removeAttribute("src");
    const returnFocus = imageLightboxState.returnFocus;
    imageLightboxState = { scale: 1, x: 0, y: 0, dragging: false, dragX: 0, dragY: 0, startX: 0, startY: 0, returnFocus: null };
    returnFocus?.focus?.();
  }

  function zoomImageLightbox(factor) {
    imageLightboxState.scale = Math.max(0.25, Math.min(8, imageLightboxState.scale * factor));
    if (imageLightboxState.scale <= 1) {
      imageLightboxState.x = 0;
      imageLightboxState.y = 0;
    }
    updateImageLightboxTransform();
  }

  function resetImageLightboxZoom() {
    imageLightboxState.scale = 1;
    imageLightboxState.x = 0;
    imageLightboxState.y = 0;
    updateImageLightboxTransform();
  }

  function updateImageLightboxTransform() {
    if (!imageLightboxImage) return;
    imageLightboxImage.style.transform = `translate(${imageLightboxState.x}px, ${imageLightboxState.y}px) scale(${imageLightboxState.scale})`;
  }

  function codeSectionMarkdown(blockID) {
    const index = blocks.findIndex((block) => block.id === blockID);
    if (index === -1) return "";

    let start = index;
    while (start > 0 && blocks[start - 1]?.type === "code") start -= 1;
    if (blocks[start - 1]?.type === "fence") start -= 1;

    let end = index;
    while (end + 1 < blocks.length && blocks[end + 1]?.type === "code") end += 1;
    if (blocks[end + 1]?.type === "fence") end += 1;

    return blocks.slice(start, end + 1).map(serializeBlock).join("\n");
  }

  function updateFormattingMenu() {
    const state = selectedTextState() || selectedBlockRangeState();
    if (!canShowFormattingMenu(state)) {
      hideFormattingMenu();
      return;
    }

    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) {
      hideFormattingMenu();
      return;
    }

    const rect = selection.getRangeAt(0).getBoundingClientRect();
    if (rect.width === 0 && rect.height === 0) {
      hideFormattingMenu();
      return;
    }

    lastFormattingSelection = state;
    const menuWidth = formattingMenu.offsetWidth || 184;
    const left = Math.min(Math.max(8, rect.left + rect.width / 2 - menuWidth / 2), window.innerWidth - menuWidth - 8);
    const top = Math.max(8, rect.top - 42);
    formattingMenu.style.left = `${left}px`;
    formattingMenu.style.top = `${top}px`;
    formattingMenu.hidden = false;
  }

  function hideFormattingMenu() {
    if (formattingMenu) formattingMenu.hidden = true;
  }

  function applyFormatting(format) {
    if (format === "code-block") {
      applyCodeBlockFormatting(selectedBlockRangeState() || selectedTextState() || lastFormattingSelection);
      return;
    }

    const state = selectedTextState() || (lastFormattingSelection?.kind === "inline" ? lastFormattingSelection : null);
    if (!state || state.start === state.end || !canFormatBlock(state.block)) return;

    const spec = formattingSpec(format);
    if (!spec) return;

    const block = findBlock(state.block.id);
    if (!block) return;

    const start = Math.max(0, Math.min(state.start, block.visibleText.length));
    const end = Math.max(start, Math.min(state.end, block.visibleText.length));
    if (start === end) return;

    recordUndoSnapshot(makeHistorySnapshot(block.id));
    resetTypingSnapshot();
    clearPendingMarkerSelection();

    const formatted = toggleInlineWrapper(block.visibleText, start, end, spec);
    blocks = editVisibleText(blocks, block.id, formatted.text);
    state.content.focus();
    state.content.textContent = formatted.text;
    setTextSelection(state.content, formatted.selectionStart, formatted.selectionEnd);
    lastFormattingSelection = {
      content: state.content,
      block: findBlock(block.id) || block,
      start: formatted.selectionStart,
      end: formatted.selectionEnd,
    };
    updateFormattingMenu();
    post("documentChanged", { formatting: format });
  }

  function selectedTextState() {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0 || selection.isCollapsed) return null;

    const range = selection.getRangeAt(0);
    const content = closestEditorContent(range.commonAncestorContainer);
    if (!content || !content.contains(range.startContainer) || !content.contains(range.endContainer)) return null;

    const row = content.closest(".editor-block");
    const block = row ? findBlock(row.dataset.blockId) : null;
    if (!block) return null;

    const start = textOffsetWithin(content, range.startContainer, range.startOffset);
    const end = textOffsetWithin(content, range.endContainer, range.endOffset);
    return {
      kind: "inline",
      content,
      block,
      start: Math.min(start, end),
      end: Math.max(start, end),
    };
  }

  function shouldIgnoreAppendTarget(target) {
    if (formattingMenu?.contains(target)) return true;
    if (target.closest?.(".copy-button")) return true;
    if (target.closest?.(".editor-content, .editor-table-cell")) return true;
    if (target.closest?.("button, input, textarea, select")) return true;
    return false;
  }

  function isTailAppendClick(event) {
    if (!editor.contains(event.target) && event.target.closest?.("main") !== editor.parentElement) return false;

    const lastElement = lastVisibleEditorElement();
    if (!lastElement) return true;

    const rect = lastElement.getBoundingClientRect();
    return event.clientY > rect.bottom + 6;
  }

  function lastVisibleEditorElement() {
    const children = Array.from(editor.children);
    for (let index = children.length - 1; index >= 0; index -= 1) {
      const element = children[index];
      if (element.getClientRects().length === 0) continue;
      if (window.getComputedStyle(element).display === "none") continue;
      return element;
    }
    return null;
  }

  function shouldAppendFromDocumentKeydown(event) {
    if (event.defaultPrevented || event.metaKey || event.ctrlKey || event.altKey || event.isComposing) return false;
    if (activeEditorInput()) return false;
    if (document.activeElement?.closest?.("button, input, textarea, select")) return false;
    return normalizedKey(event.key) === "Enter" || event.key.length === 1;
  }

  function activeEditorInput() {
    return document.activeElement?.closest?.(".editor-content, .editor-table-cell") || null;
  }

  function selectedBlockRangeState() {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0 || selection.isCollapsed) return null;

    const range = selection.getRangeAt(0);
    const startContent = closestEditorContent(range.startContainer);
    const endContent = closestEditorContent(range.endContainer);
    if (!startContent || !endContent) return null;

    const startRow = startContent.closest(".editor-block");
    const endRow = endContent.closest(".editor-block");
    if (!startRow || !endRow) return null;

    const startIndex = blocks.findIndex((block) => block.id === startRow.dataset.blockId);
    const endIndex = blocks.findIndex((block) => block.id === endRow.dataset.blockId);
    if (startIndex === -1 || endIndex === -1) return null;

    const firstIndex = Math.min(startIndex, endIndex);
    const lastIndex = Math.max(startIndex, endIndex);
    const firstBlock = blocks[firstIndex];
    if (!firstBlock) return null;

    return {
      kind: "block-range",
      block: firstBlock,
      content: startContent,
      startIndex: firstIndex,
      endIndex: lastIndex,
    };
  }

  function closestEditorContent(node) {
    if (!node) return null;
    if (node.nodeType === Node.ELEMENT_NODE) return node.closest(".editor-content");
    return node.parentElement?.closest(".editor-content") || null;
  }

  function textOffsetWithin(root, targetNode, targetOffset) {
    if (targetNode === root) {
      return Array.from(root.childNodes)
        .slice(0, targetOffset)
        .reduce((total, node) => total + (node.textContent?.length || 0), 0);
    }

    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    let offset = 0;
    let node;
    while ((node = walker.nextNode())) {
      if (node === targetNode) return offset + targetOffset;
      offset += node.nodeValue.length;
    }
    return offset;
  }

  function canFormatBlock(block) {
    return Boolean(block) && !block.unlocked && block.type !== "image" && !isRawDisplayType(block);
  }

  function canShowFormattingMenu(state) {
    if (!state) return false;
    if (state.kind === "block-range") return canFormatBlockRange(state);
    return state.start !== state.end && canFormatBlock(state.block);
  }

  function canFormatBlockRange(state) {
    if (!state || state.startIndex > state.endIndex) return false;
    return blocks.slice(state.startIndex, state.endIndex + 1).every(canFormatBlock);
  }

  function blockRangeFromFormattingState(state) {
    if (!state) return null;
    if (state.kind === "block-range") return state;
    const index = blocks.findIndex((block) => block.id === state.block?.id);
    if (index === -1) return null;
    return { kind: "block-range", block: blocks[index], content: state.content, startIndex: index, endIndex: index };
  }

  function applyCodeBlockFormatting(state) {
    const rangeState = blockRangeFromFormattingState(state);
    if (!rangeState || !canFormatBlockRange(rangeState)) return;

    const selectedBlocks = blocks.slice(rangeState.startIndex, rangeState.endIndex + 1);
    const source = codeBlockFormatterSource(selectedBlocks);
    const replacementBlocks = parseMarkdown(source);
    const snapshotBlockID = selectedBlocks[0]?.id;

    recordUndoSnapshot(makeHistorySnapshot(snapshotBlockID));
    resetTypingSnapshot();
    clearPendingMarkerSelection();

    blocks = reindexBlocks([
      ...blocks.slice(0, rangeState.startIndex),
      ...replacementBlocks,
      ...blocks.slice(rangeState.endIndex + 1),
    ]);

    const focusIndex = Math.min(rangeState.startIndex + 1, blocks.length - 1);
    const focusBlock = blocks[focusIndex];
    render(focusBlock?.id || null);
    lastFormattingSelection = null;
    hideFormattingMenu();
    post("documentChanged", { formatting: "code-block" });
  }

  function codeBlockFormatterSource(selectedBlocks) {
    const sources = selectedBlocks.map(serializeBlock);
    const first = sources[0]?.trim() || "";
    const last = sources[sources.length - 1]?.trim() || "";
    const malformedOpening = first.match(/^`{1,2}([0-9A-Za-z_-]+)?$/);
    const malformedClosing = /^`{1,2}$/.test(last);

    if (sources.length >= 2 && malformedOpening && malformedClosing) {
      const language = malformedOpening[1] || "";
      return ["```" + language, ...sources.slice(1, -1), "```"].join("\n");
    }

    return ["```", ...sources, "```"].join("\n");
  }

  function formattingSpec(format) {
    switch (format) {
      case "bold": return { prefix: "**", suffix: "**" };
      case "italic": return { prefix: "*", suffix: "*" };
      case "highlight": return { prefix: "<mark>", suffix: "</mark>" };
      case "code": return { prefix: "`", suffix: "`" };
      case "link": return { prefix: "[", suffix: "](https://)", selectURLPlaceholder: true };
      default: return null;
    }
  }

  function toggleInlineWrapper(value, start, end, spec) {
    const { prefix, suffix } = spec;
    const selected = value.slice(start, end);
    const wrappedStart = start - prefix.length;
    const wrappedEnd = end + suffix.length;
    const hasWrapper = wrappedStart >= 0
      && value.slice(wrappedStart, start) === prefix
      && value.slice(end, wrappedEnd) === suffix;

    if (hasWrapper) {
      const selectionStart = wrappedStart;
      const text = value.slice(0, wrappedStart) + selected + value.slice(wrappedEnd);
      return {
        text,
        selectionStart,
        selectionEnd: selectionStart + selected.length,
      };
    }

    let selectionStart = start + prefix.length;
    let selectionEnd = selectionStart + selected.length;
    if (spec.selectURLPlaceholder) {
      selectionStart = start + prefix.length + selected.length + 2;
      selectionEnd = selectionStart + "https://".length;
    }

    return {
      text: value.slice(0, start) + prefix + selected + suffix + value.slice(end),
      selectionStart,
      selectionEnd,
    };
  }

  function captureUndoSnapshot(blockID, event) {
    const snapshot = makeHistorySnapshot(blockID);
    const now = Date.now();
    if (isCoalescedTypingInput(event) && activeTypingSnapshot?.blockID === blockID && now - lastTypingAt < 1200) {
      pendingUndoSnapshot = activeTypingSnapshot;
      lastTypingAt = now;
      return;
    }

    activeTypingSnapshot = { ...snapshot, blockID };
    pendingUndoSnapshot = activeTypingSnapshot;
    lastTypingAt = now;

    if (!isCoalescedTypingInput(event)) {
      resetTypingSnapshot();
    }
  }

  function recordUndoSnapshot(snapshot = null) {
    const candidate = snapshot || pendingUndoSnapshot || makeHistorySnapshot();
    pendingUndoSnapshot = null;
    if (!candidate) return;
    pushHistorySnapshot(undoStack, candidate);
    redoStack.length = 0;
  }

  function pushHistorySnapshot(stack, snapshot) {
    if (!snapshot || typeof snapshot.markdown !== "string") return;
    if (stack.at(-1)?.markdown === snapshot.markdown) return;
    stack.push(snapshot);
    if (stack.length > maxHistoryDepth) stack.shift();
  }

  function makeHistorySnapshot(fallbackBlockID = null) {
    return {
      markdown: serializeBlocks(blocks),
      focusID: focusedBlockID() || fallbackBlockID,
      caretOffset: currentCaretOffset(),
    };
  }

  function undo() {
    restoreHistorySnapshot(undoStack, redoStack, "undo");
  }

  function redo() {
    restoreHistorySnapshot(redoStack, undoStack, "redo");
  }

  function restoreHistorySnapshot(sourceStack, destinationStack, action) {
    const snapshot = sourceStack.pop();
    if (!snapshot) return;

    clearPendingCommit();
    clearPendingMarkerSelection();
    resetTypingSnapshot();
    pushHistorySnapshot(destinationStack, makeHistorySnapshot(snapshot.focusID));
    blocks = parseMarkdown(snapshot.markdown);
    render(snapshot.focusID, null, false, snapshot.caretOffset);
    post("documentChanged", { history: action });
  }

  function focusedBlockID() {
    const block = document.activeElement?.closest?.(".editor-block");
    return block?.dataset?.blockId || null;
  }

  function resetTypingSnapshot() {
    activeTypingSnapshot = null;
    lastTypingAt = 0;
  }

  function isCoalescedTypingInput(event) {
    const type = event?.inputType || "";
    return type === "insertText"
      || type === "insertCompositionText"
      || type === "deleteContentBackward"
      || type === "deleteContentForward";
  }

  function parseMarkdown(markdown) {
    const lines = markdown.split("\n");
    const parsedBlocks = [];
    let inFence = false;
    const anchorCounts = new Map();

    lines.forEach((source, index) => {
      const parsed = parseLine(source, { index, inFence });
      if (parsed.type === "heading") parsed.anchorID = nextAnchor(parsed.visibleText, anchorCounts);
      parsedBlocks.push(parsed);
      if (parsed.type === "fence") inFence = !inFence;
    });

    return classifyTableBlocks(parsedBlocks);
  }

  function serializeBlocks(sourceBlocks) {
    return sourceBlocks.map(serializeBlock).join("\n");
  }

  function editVisibleText(sourceBlocks, id, visibleText) {
    return sourceBlocks.map((block) => {
      if (block.id !== id) return block;
      return { ...block, visibleText, source: block.prefix + visibleText + block.suffix };
    });
  }

  function replaceBlockWithSource(sourceBlocks, id, source) {
    return sourceBlocks.map((block) => {
      if (block.id !== id) return block;
      return { ...parseLine(source, { index: block.index, inFence: block.type === "code" }), id: block.id };
    });
  }

  function unlockBlock(sourceBlocks, id) {
    return sourceBlocks.map((block) => {
      if (block.id !== id) return block;
      return { ...block, unlocked: true, visibleText: serializeBlock(block), prefix: "", suffix: "" };
    });
  }

  function markerUnlockTarget(block) {
    if (block.type === "image") {
      return {
        focusID: block.id,
        selectionRange: { start: 0, end: block.visibleText.length },
        unlock: (sourceBlocks) => unlockBlock(sourceBlocks, block.id),
      };
    }

    const codeRange = codeSectionRange(blocks, block.id);
    if (codeRange) {
      const extracted = codeLineExtractionTarget(blocks, block.id);
      if (extracted) {
        return {
          focusID: extracted.focusID,
          selectionRange: extracted.selectionRange,
          documentChanged: "extract-code-line",
          unlock: (sourceBlocks) => extractCodeLineFromSection(sourceBlocks, block.id),
        };
      }

      const openingFence = blocks[codeRange.start];
      return {
        focusID: openingFence.id,
        selectionRange: { ...markerSelectionRange(openingFence), unwrapCodeBlock: true },
        unlock: (sourceBlocks) => unlockCodeSection(sourceBlocks, block.id),
      };
    }

    return {
      focusID: block.id,
      selectionRange: markerSelectionRange(block),
      unlock: (sourceBlocks) => unlockBlock(sourceBlocks, block.id),
    };
  }

  function codeLineExtractionTarget(sourceBlocks, id) {
    const index = sourceBlocks.findIndex((block) => block.id === id);
    const block = sourceBlocks[index];
    if (!block || block.type !== "code") return null;
    const range = codeSectionRange(sourceBlocks, id);
    if (!range) return null;

    const parsed = parseLine(serializeBlock(block), { index: block.index, inFence: false });
    if (!isExtractableCodeMarkdown(parsed)) return null;

    const beforeCodeCount = index - range.start - 1;
    const focusIndex = range.start + (beforeCodeCount > 0 ? beforeCodeCount + 2 : 0);

    return {
      focusID: `line-${focusIndex}`,
      selectionRange: markerSelectionRange(parsed),
    };
  }

  function isExtractableCodeMarkdown(block) {
    return ["heading", "unordered-list", "ordered-list", "quote"].includes(block?.type);
  }

  function unlockCodeSection(sourceBlocks, id) {
    const range = codeSectionRange(sourceBlocks, id);
    if (!range) return unlockBlock(sourceBlocks, id);

    return sourceBlocks.map((block, index) => {
      if (index < range.start || index > range.end) return block;
      return { ...block, unlocked: true, visibleText: serializeBlock(block), prefix: "", suffix: "" };
    });
  }

  function unwrapCodeBlock(sourceBlocks, id) {
    const range = codeSectionRange(sourceBlocks, id);
    if (!range) return sourceBlocks;

    const replacementBlocks = sourceBlocks
      .slice(range.start + 1, range.end)
      .map((block, offset) => parseLine(serializeBlock(block), { index: range.start + offset, inFence: false }));

    return reindexBlocks([
      ...sourceBlocks.slice(0, range.start),
      ...replacementBlocks,
      ...sourceBlocks.slice(range.end + 1),
    ]);
  }

  function extractCodeLineFromSection(sourceBlocks, id) {
    const range = codeSectionRange(sourceBlocks, id);
    const index = sourceBlocks.findIndex((block) => block.id === id);
    if (!range || index <= range.start || index >= range.end) return sourceBlocks;

    const openingFence = serializeBlock(sourceBlocks[range.start]);
    const closingFence = serializeBlock(sourceBlocks[range.end]);
    const beforeCode = sourceBlocks.slice(range.start + 1, index).map(serializeBlock);
    const extractedSource = serializeBlock(sourceBlocks[index]);
    const afterCode = sourceBlocks.slice(index + 1, range.end).map(serializeBlock);
    const replacementSources = [];

    if (beforeCode.length > 0) {
      replacementSources.push(openingFence, ...beforeCode, closingFence);
    }

    replacementSources.push(extractedSource);

    if (afterCode.length > 0) {
      replacementSources.push(openingFence, ...afterCode, closingFence);
    }

    const extractedReplacementIndex = beforeCode.length > 0 ? beforeCode.length + 2 : 0;
    const replacementBlocks = parseMarkdown(replacementSources.join("\n")).map((block, replacementIndex) => {
      if (replacementIndex !== extractedReplacementIndex) return block;
      return { ...block, unlocked: true, visibleText: serializeBlock(block), prefix: "", suffix: "" };
    });

    return reindexBlocks([
      ...sourceBlocks.slice(0, range.start),
      ...replacementBlocks,
      ...sourceBlocks.slice(range.end + 1),
    ]);
  }

  function codeSectionRange(sourceBlocks, id) {
    const index = sourceBlocks.findIndex((block) => block.id === id);
    if (index === -1) return null;

    let start = index;
    while (start > 0 && sourceBlocks[start - 1]?.type === "code") start -= 1;
    if (sourceBlocks[start - 1]?.type === "fence") start -= 1;

    let end = index;
    while (end + 1 < sourceBlocks.length && sourceBlocks[end + 1]?.type === "code") end += 1;
    if (sourceBlocks[end + 1]?.type === "fence") end += 1;

    if (sourceBlocks[start]?.type !== "fence" || sourceBlocks[end]?.type !== "fence" || start >= end) return null;
    return { start, end };
  }

  function updateUnlockedDraft(sourceBlocks, id, source) {
    return sourceBlocks.map((block) => {
      if (block.id !== id) return block;
      return { ...block, source, visibleText: source, prefix: "", suffix: "", unlocked: true };
    });
  }

  function commitUnlockedSource(sourceBlocks, id, force = false) {
    const block = sourceBlocks.find((candidate) => candidate.id === id);
    if (!block) return sourceBlocks;
    if (!force && shouldWaitForMoreMarkerInput(block.visibleText)) return sourceBlocks;
    if (codeSectionRange(sourceBlocks, id)) return parseMarkdown(serializeBlocks(sourceBlocks));
    return replaceBlockWithSource(sourceBlocks, id, block.visibleText);
  }

  function appendBlockAtEnd(initialSource = "") {
    const source = initialSource || "";
    const last = blocks[blocks.length - 1];

    if (source === "" && last?.type === "blank") {
      render(last.id, null, true);
      return;
    }

    recordUndoSnapshot(makeHistorySnapshot(last?.id));
    resetTypingSnapshot();
    clearPendingMarkerSelection();

    if (source !== "" && blocks.length === 1 && last?.type === "blank") {
      const parsed = parseLine(source, { index: 0, inFence: false });
      blocks = [{ ...parsed, id: last.id }];
      render(last.id, null, true);
      post("documentChanged", { append: "tail" });
      return;
    }

    const index = blocks.length;
    const parsed = parseLine(source, { index, inFence: false });
    blocks = reindexBlocks([...blocks, parsed]);
    const appended = blocks[blocks.length - 1];
    render(appended?.id || null, null, true);
    post("documentChanged", { append: "tail" });
  }

  function shouldDeleteEmptyCodeLine(block, event) {
    const key = normalizedKey(event.key);
    if (key !== "Backspace" && key !== "Delete") return false;
    if (event.metaKey || event.ctrlKey || event.altKey) return false;
    if (block.type !== "code" || serializeBlock(block) !== "") return false;
    return Boolean(codeSectionRange(blocks, block.id));
  }

  function deleteEmptyCodeLine(id, key) {
    const index = blocks.findIndex((block) => block.id === id);
    const range = codeSectionRange(blocks, id);
    if (index === -1 || !range) return { id, caretEnd: false };

    const direction = key === "Backspace" ? "backward" : "forward";
    const focusIndex = focusCodeLineAfterDeletion(blocks, range, index, direction);
    blocks = reindexBlocks([...blocks.slice(0, index), ...blocks.slice(index + 1)]);

    if (focusIndex === null) return { id: blocks[Math.max(0, index - 1)]?.id || null, caretEnd: true };
    const reindexedFocus = focusIndex > index ? focusIndex - 1 : focusIndex;
    return { id: blocks[reindexedFocus]?.id || null, caretEnd: direction === "backward" };
  }

  function focusCodeLineAfterDeletion(sourceBlocks, range, deletedIndex, direction) {
    const forward = () => {
      for (let index = deletedIndex + 1; index < range.end; index += 1) {
        if (sourceBlocks[index]?.type === "code") return index;
      }
      return null;
    };
    const backward = () => {
      for (let index = deletedIndex - 1; index > range.start; index -= 1) {
        if (sourceBlocks[index]?.type === "code") return index;
      }
      return null;
    };

    return direction === "backward" ? backward() ?? forward() : forward() ?? backward();
  }

  function splitBlockAtCaret(id, offset) {
    const index = blocks.findIndex((block) => block.id === id);
    if (index === -1) return id;
    const block = blocks[index];
    const before = block.visibleText.slice(0, offset);
    const after = block.visibleText.slice(offset);
    if (shouldExitEmptyContinuationBlock(block, before, after)) {
      const blank = parseLine("", { index, inFence: false });
      blocks = reindexBlocks([...blocks.slice(0, index), { ...blank, id: block.id }, ...blocks.slice(index + 1)]);
      return blocks[index].id;
    }
    const current = editVisibleText([block], block.id, before)[0];
    const nextSource = continuationSource(block, after);
    const next = parseLine(nextSource, { index: index + 1, inFence: block.type === "code" });
    blocks = reindexBlocks([...blocks.slice(0, index), current, next, ...blocks.slice(index + 1)]);
    return blocks[index + 1].id;
  }

  function shouldExitEmptyContinuationBlock(block, before, after) {
    return ["unordered-list", "ordered-list", "quote"].includes(block.type)
      && block.visibleText.trim() === ""
      && before === ""
      && after === "";
  }

  function continuationSource(block, after) {
    if (block.type === "unordered-list" && block.visibleText.trim() !== "") return `${block.marker} ${after}`;
    if (block.type === "ordered-list" && block.visibleText.trim() !== "") return `${nextOrderedListMarker(block.marker)} ${after}`;
    if (block.type === "quote" && block.visibleText.trim() !== "") return `> ${after}`;
    return after;
  }

  function nextOrderedListMarker(marker) {
    const [, number = "", delimiter = "."] = marker.match(/^(\d+)([.)])$/) ?? [];
    if (!number) return marker;
    return `${Number(number) + 1}${delimiter}`;
  }

  function parseLine(source, { index, inFence }) {
    if (inFence && !isFence(source)) return block({ index, source, type: "code", visibleText: source, prefix: "", suffix: "" });
    if (source.length === 0) return block({ index, source, type: "blank", visibleText: "", prefix: "", suffix: "" });
    return parseFence(source, index)
      || parseHeading(source, index)
      || parseUnorderedList(source, index)
      || parseOrderedList(source, index)
      || parseQuote(source, index)
      || parseImage(source, index)
      || block({ index, source, type: "paragraph", visibleText: source, prefix: "", suffix: "" });
  }

  function classifyTableBlocks(sourceBlocks) {
    const result = [...sourceBlocks];
    for (let index = 0; index < result.length - 1; index += 1) {
      if (result[index].type !== "paragraph" || result[index + 1].type !== "paragraph") continue;
      if (!looksLikeTableRow(result[index].source) || !isTableSeparatorLine(result[index + 1].source)) continue;

      const alignments = parseTableAlignments(result[index + 1].source);
      result[index] = tableBlock(result[index], "table-header", alignments);
      result[index + 1] = { ...result[index + 1], type: "table-separator", alignments, visibleText: result[index + 1].source };

      let rowIndex = index + 2;
      while (rowIndex < result.length && result[rowIndex].type === "paragraph" && looksLikeTableRow(result[rowIndex].source)) {
        result[rowIndex] = tableBlock(result[rowIndex], "table-row", alignments);
        rowIndex += 1;
      }
      index = rowIndex - 1;
    }
    return result;
  }

  function tableBlock(sourceBlock, type, alignments) {
    return {
      ...sourceBlock,
      type,
      cells: parseTableRow(sourceBlock.source),
      alignments,
      visibleText: sourceBlock.source,
      prefix: "",
      suffix: "",
    };
  }

  function looksLikeTableRow(source) {
    const trimmed = source.trim();
    return trimmed.includes("|") && parseTableRow(source).length > 1;
  }

  function isTableSeparatorLine(source) {
    if (!looksLikeTableRow(source)) return false;
    return parseTableRow(source).every((cell) => /^:?-{3,}:?$/.test(cell.replace(/\s+/g, "")));
  }

  function parseTableAlignments(source) {
    return parseTableRow(source).map((cell) => {
      const marker = cell.replace(/\s+/g, "");
      const left = marker.startsWith(":");
      const right = marker.endsWith(":");
      if (left && right) return "center";
      if (right) return "right";
      if (left) return "left";
      return "left";
    });
  }

  function parseTableRow(source) {
    let row = source.trim();
    if (row.startsWith("|")) row = row.slice(1);
    if (row.endsWith("|")) row = row.slice(0, -1);
    return row.split("|").map((cell) => cell.trim());
  }

  function parseFence(source, index) {
    const [, leading = "", marker = "", language = ""] = source.match(/^(\s*)(```|~~~)(.*)$/) ?? [];
    if (!marker) return null;
    return block({ index, source, type: "fence", marker, visibleText: language.trim(), prefix: leading + marker, suffix: "" });
  }

  function parseHeading(source, index) {
    const [, leading = "", marker = "", body = ""] = source.match(/^(\s{0,3})(#{1,6})\s+(.*)$/) ?? [];
    if (!marker) return null;
    const visibleText = body.replace(/\s+#+\s*$/, "");
    const suffix = body.slice(visibleText.length);
    return block({ index, source, type: "heading", level: marker.length, visibleText, prefix: leading + marker + " ", suffix });
  }

  function parseUnorderedList(source, index) {
    const [, leading = "", marker = "", body = ""] = source.match(/^(\s*)([-+*])\s+(.*)$/) ?? [];
    if (!marker) return null;
    return block({ index, source, type: "unordered-list", marker, visibleText: body, prefix: leading + marker + " ", suffix: "" });
  }

  function parseOrderedList(source, index) {
    const [, leading = "", marker = "", body = ""] = source.match(/^(\s*)(\d+[.)])\s+(.*)$/) ?? [];
    if (!marker) return null;
    return block({ index, source, type: "ordered-list", marker, visibleText: body, prefix: leading + marker + " ", suffix: "" });
  }

  function parseQuote(source, index) {
    const [, leading = "", body = ""] = source.match(/^(\s*)>\s?(.*)$/) ?? [];
    if (!source.trimStart().startsWith(">")) return null;
    return block({ index, source, type: "quote", visibleText: body, prefix: leading + "> ", suffix: "" });
  }

  function parseImage(source, index) {
    const parsed = parseImageSource(source.trim());
    if (!parsed) return null;
    return block({ index, source, type: "image", visibleText: source, prefix: "", suffix: "", ...parsed });
  }

  function parseImageSource(source) {
    const match = source.match(/^!\[([^\]]*)\]\(([\s\S]*)\)$/);
    if (!match) return null;

    const alt = match[1] || "";
    const target = parseImageTarget(match[2]);
    if (!target.destination) return null;
    return { alt, destination: target.destination, title: target.title };
  }

  function parseImageTarget(value) {
    let target = String(value || "").trim();
    let title = "";
    const titleMatch = target.match(/^(.*?)(?:\s+(["'])(.*?)\2)\s*$/);
    if (titleMatch) {
      target = titleMatch[1].trim();
      title = titleMatch[3] || "";
    }

    if (target.startsWith("<") && target.endsWith(">")) {
      target = target.slice(1, -1).trim();
    }

    return { destination: target, title };
  }

  function block(values) {
    return { id: `line-${values.index}`, index: values.index, marker: "", level: 0, unlocked: false, anchorID: "", ...values };
  }

  function serializeBlock(block) {
    if (isTableBlock(block)) return block.source;
    if (block.type === "image" && !block.unlocked) return block.source;
    if (block.unlocked) return block.visibleText;
    return block.prefix + block.visibleText + block.suffix;
  }

  function reindexBlocks(sourceBlocks) {
    return sourceBlocks.map((block, index) => ({ ...block, id: `line-${index}`, index }));
  }

  function markerText(block) {
    if (block.unlocked) return "raw";
    switch (block.type) {
      case "heading": return "#".repeat(block.level);
      case "unordered-list":
      case "ordered-list": return block.marker;
      case "quote": return ">";
      case "fence": return block.marker;
      case "code": return "code";
      default: return "";
    }
  }

  function markerViewText(block) {
    if (block.type === "ordered-list") return block.marker;
    return "";
  }

  function renderBlockContent(element, block) {
    if (block.type === "image" && !block.unlocked) {
      renderImageBlockContent(element, block);
      return;
    }
    if (block.unlocked || isRawDisplayType(block)) {
      element.textContent = block.visibleText;
      return;
    }
    element.innerHTML = inlineMarkdownHTML(block.visibleText);
  }

  function renderImageBlockContent(element, block) {
    element.innerHTML = "";
    const safeSrc = safeImageURL(block.destination);
    if (!safeSrc) {
      const fallback = document.createElement("div");
      fallback.className = "editor-image-fallback";
      fallback.textContent = imageFallbackText(block, "unsupported source");
      element.append(fallback);
      return;
    }

    const figure = document.createElement("figure");
    figure.className = "editor-image-frame";

    const image = document.createElement("img");
    image.src = safeSrc;
    image.alt = block.alt || "";
    if (block.title) image.title = block.title;
    image.dataset.imagePreview = "true";
    image.dataset.imageSrc = safeSrc;
    image.dataset.imageAlt = block.alt || "";
    image.dataset.imageTitle = block.title || "";
    image.addEventListener("error", () => {
      figure.classList.add("editor-image-missing");
      fallback.hidden = false;
    });

    const button = document.createElement("button");
    button.type = "button";
    button.className = "image-action-button";
    button.dataset.openImage = "true";
    button.dataset.imageSrc = safeSrc;
    button.dataset.imageAlt = block.alt || "";
    button.dataset.imageTitle = block.title || "";
    button.setAttribute("aria-label", `Open image full screen: ${block.alt || block.title || "Image"}`);
    button.setAttribute("title", "Open image full screen");
    button.innerHTML = zoomIconSVG;

    const fallback = document.createElement("div");
    fallback.className = "editor-image-fallback";
    fallback.hidden = true;
    fallback.textContent = imageFallbackText(block, "missing file");

    figure.append(image, button, fallback);
    element.append(figure);
  }

  function imageFallbackText(block, reason) {
    const label = block.alt || "Image";
    const destination = block.destination ? ` (${block.destination})` : "";
    return `Image unavailable: ${label}${destination} - ${reason}`;
  }

  function isRawDisplayType(block) {
    return block.type === "code" || block.type === "fence";
  }

  function isTableBlock(block) {
    return block?.type === "table-header" || block?.type === "table-separator" || block?.type === "table-row";
  }

  function inlineMarkdownHTML(value) {
    const placeholders = [];
    let html = escapeHTML(value);

    html = html.replace(/`([^`]+)`/g, (_match, code) => placeholder(placeholders, `<code>${code}</code>`));
    html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, (match, alt, target) => {
      const parsed = parseImageTarget(target);
      const src = safeImageURL(parsed.destination);
      if (!src) return match;
      const title = parsed.title ? ` title="${escapeAttribute(parsed.title)}"` : "";
      return placeholder(
        placeholders,
        `<img class="editor-inline-image" data-image-preview="true" data-image-src="${escapeAttribute(src)}" data-image-alt="${escapeAttribute(alt)}" data-image-title="${escapeAttribute(parsed.title)}" src="${escapeAttribute(src)}" alt="${escapeAttribute(alt)}"${title}>`
      );
    });
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_match, label, href) => {
      return placeholder(placeholders, `<a href="${escapeAttribute(href)}">${label}</a>`);
    });
    html = html.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
    html = html.replace(/__([^_]+)__/g, "<strong>$1</strong>");
    html = html.replace(/(^|[^*])\*([^*]+)\*/g, "$1<em>$2</em>");
    html = html.replace(/(^|[^_])_([^_]+)_/g, "$1<em>$2</em>");

    placeholders.forEach((value, index) => {
      html = html.split(`%%MDPH${index}%%`).join(value);
    });
    html = html.replace(/&lt;mark&gt;([\s\S]*?)&lt;\/mark&gt;/g, "<mark>$1</mark>");
    return html;
  }

  function placeholder(values, value) {
    const token = `%%MDPH${values.length}%%`;
    values.push(value);
    return token;
  }

  function escapeHTML(value) {
    return value
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function escapeAttribute(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/"/g, "&quot;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  function safeImageURL(value) {
    const url = String(value || "").trim();
    if (!url || /[\u0000-\u001f\u007f]/.test(url)) return "";
    if (url.startsWith("//")) return "";
    const scheme = url.match(/^([A-Za-z][A-Za-z0-9+.-]*):/);
    if (!scheme) return url;
    const normalized = scheme[1].toLowerCase();
    if (normalized === "http" || normalized === "https" || normalized === "file") return url;
    if (normalized === "data" && /^data:image\/(?:png|jpe?g|gif|webp|svg\+xml);/i.test(url)) return url;
    return "";
  }

  function shouldParseTypedSource(block, source) {
    if (block.type !== "blank" && block.type !== "paragraph") return false;
    const parsed = parseLine(source, { index: block.index, inFence: false });
    return parsed.type !== "blank" && parsed.type !== "paragraph";
  }

  function shouldPromoteBlankTypedText(block, source) {
    return block.type === "blank" && source.length > 0;
  }

  function shouldReplaceFormattedTypedSource(block, source) {
    if (!["unordered-list", "ordered-list", "quote", "heading"].includes(block.type)) return false;
    const parsed = parseLine(source, { index: block.index, inFence: false });
    return parsed.type !== "blank" && parsed.type !== "paragraph";
  }

  function shouldWaitForMoreMarkerInput(source) {
    return /^(#{1,6}|[-+*]|>\s*|`{1,2}[0-9A-Za-z_-]*)$/.test(source);
  }

  function markerSelectionRange(block) {
    const source = serializeBlock(block);
    const leadingLength = source.match(/^\s*/)?.[0]?.length ?? 0;
    return { start: leadingLength, end: leadingLength + markerTokenLength(block) };
  }

  function markerTokenLength(block) {
    switch (block.type) {
      case "heading": return block.level;
      case "unordered-list":
      case "ordered-list":
      case "fence": return block.marker.length;
      case "quote": return 1;
      default: return 0;
    }
  }

  function findBlock(id) {
    return blocks.find((block) => block.id === id);
  }

  function currentCaretOffset() {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return 0;
    return selection.getRangeAt(0).startOffset;
  }

  function setTextSelection(element, start, end) {
    if (!element) return;
    const textNode = element.firstChild;
    const safeStart = Math.max(0, Math.min(start, element.textContent.length));
    const safeEnd = Math.max(safeStart, Math.min(end, element.textContent.length));
    const range = document.createRange();
    range.setStart(textNode ?? element, textNode ? safeStart : 0);
    range.setEnd(textNode ?? element, textNode ? safeEnd : 0);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
  }

  function moveCaretToStart(element) {
    setTextSelection(element, 0, 0);
  }

  function moveCaretToEnd(element) {
    if (!element) return;
    setTextSelection(element, element.textContent.length, element.textContent.length);
  }

  function replaceRangeInContent(element, start, end, replacement) {
    const value = element.textContent;
    const safeStart = Math.max(0, Math.min(start, value.length));
    const safeEnd = Math.max(safeStart, Math.min(end, value.length));
    element.textContent = value.slice(0, safeStart) + replacement + value.slice(safeEnd);
    setTextSelection(element, safeStart + replacement.length, safeStart + replacement.length);
  }

  function scheduleUnlockedCommit(id) {
    clearPendingCommit();
    pendingCommitTimer = window.setTimeout(() => {
      pendingCommitTimer = null;
      const current = findBlock(id);
      if (!current?.unlocked || shouldWaitForMoreMarkerInput(current.visibleText)) return;
      blocks = commitUnlockedSource(blocks, id);
      render(id, null, true);
      post("documentChanged");
    }, 140);
  }

  function clearPendingCommit() {
    if (!pendingCommitTimer) return;
    window.clearTimeout(pendingCommitTimer);
    pendingCommitTimer = null;
  }

  function clearPendingMarkerSelection() {
    pendingMarkerSelection = null;
  }

  function isMarkerReplacementKey(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return false;
    return event.key.length === 1 || event.key === "Backspace" || event.key === "Delete";
  }

  function linkPayload(link) {
    const href = link.getAttribute("href") || "";
    return { href, resolvedHref: link.href || href };
  }

  function closestLink(target) {
    const element = target?.nodeType === Node.ELEMENT_NODE ? target : target?.parentElement;
    return element?.closest?.("a[href]") || null;
  }

  function hasLinkOpenModifier(event) {
    return Boolean(event.metaKey || event.ctrlKey);
  }

  function activateLink(link, event, lastActivation) {
    event.preventDefault();
    const payload = linkPayload(link);
    const activationKey = payload.resolvedHref || payload.href;
    const now = Date.now();
    if (lastActivation.href === activationKey && now - lastActivation.at < 450) return;
    lastActivation.href = activationKey;
    lastActivation.at = now;
    post("linkActivated", payload, false);
  }

  function shouldUnlockFromKey(eventLike, caretOffset) {
    return normalizedKey(eventLike.key) === "ArrowLeft" && caretOffset === 0 && !eventLike.metaKey;
  }

  function classifyShortcut(eventLike) {
    const meta = Boolean(eventLike.metaKey);
    const key = normalizedKey(eventLike.key);
    if (!meta) return "editor";
    if (key === "z" && eventLike.shiftKey) return "redo";
    if (key === "z") return "undo";
    if (key === "y") return "redo";
    if (key === "b") return "format-bold";
    if (key === "i") return "format-italic";
    if (key === "e") return "format-code";
    if (key === "k") return "format-link";
    if (key === "h" && eventLike.ctrlKey) return "format-highlight";
    if (key === "s") return "save";
    if (["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(key)) return "native-navigation";
    if (key === "o" || key === "f" || key === "/" || key === "r" || key === "[" || key === "]") return "native-command";
    return "editor";
  }

  function isFence(source) {
    return /^\s*(```|~~~)/.test(source);
  }

  function normalizedKey(key) {
    if (!key) return "";
    return key.length === 1 ? key.toLowerCase() : key;
  }

  function nextAnchor(title, counts) {
    const base = slug(title || "section");
    const count = counts.get(base) || 0;
    counts.set(base, count + 1);
    return count === 0 ? base : `${base}-${count + 1}`;
  }

  function slug(value) {
    const collapsed = value.toLocaleLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "");
    return collapsed || "section";
  }
})();
"""#
}
