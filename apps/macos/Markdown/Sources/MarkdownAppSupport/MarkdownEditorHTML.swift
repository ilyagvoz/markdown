import Foundation

public enum MarkdownEditorHTML {
    public static func document(markdown: String, title: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
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

            .formatting-menu [data-format="link"] {
              min-width: 42px;
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
              margin: 0.18em 0 0.18em 1.45em;
            }

            .editor-block-unordered-list .editor-content,
            .editor-block-ordered-list .editor-content {
              position: relative;
            }

            .editor-block-unordered-list .editor-content::before {
              content: "\\2022";
              position: absolute;
              left: -1.1em;
              color: var(--text);
            }

            .editor-block-ordered-list .editor-content::before {
              content: attr(data-marker-view);
              position: absolute;
              left: -1.75em;
              min-width: 1.35em;
              text-align: right;
              color: var(--text);
            }

            .editor-block-quote .editor-content {
              color: var(--muted);
              border-left: 4px solid var(--quote);
              padding-left: 1.05em;
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
          <main>
            <div class="editor" data-editor aria-label="Markdown live preview editor"></div>
          </main>
          <div class="formatting-menu" data-formatting-menu role="toolbar" aria-label="Formatting" hidden>
            <button type="button" data-format="bold" aria-label="Bold">B</button>
            <button type="button" data-format="italic" aria-label="Italic">I</button>
            <button type="button" data-format="highlight" aria-label="Highlight">H</button>
            <button type="button" data-format="code" aria-label="Inline code">`</button>
            <button type="button" data-format="link" aria-label="Link">Link</button>
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
  let lastFormattingSelection = null;

  render();
  post("ready");
  installFormattingMenu();
  installBlankDocumentClickTarget();

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
      const emptyRow = editor.querySelector(".editor-block-empty-document");
      if (!emptyRow) return;
      if (formattingMenu?.contains(event.target)) return;
      const content = emptyRow.querySelector(".editor-content");
      if (!content) return;
      content.focus();
      moveCaretToEnd(content);
    });
  }

  function render(focusID = null, selectionRange = null, caretEnd = false, caretOffset = null) {
    hideFormattingMenu();
    editor.innerHTML = "";
    blocks = reindexBlocks(blocks);

    for (const block of blocks) {
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
      content.contentEditable = "true";
      content.spellcheck = true;
      content.dataset.raw = block.visibleText;
      content.dataset.markerView = markerViewText(block);
      renderBlockContent(content, block);
      content.setAttribute("aria-label", `${block.type} line ${block.index + 1}`);

      content.addEventListener("focus", () => {
        if (block.unlocked || isRawDisplayType(block)) return;
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

        if (block.unlocked && pendingMarkerSelection?.id === block.id && isMarkerReplacementKey(event)) {
          event.preventDefault();
          recordUndoSnapshot(makeHistorySnapshot(block.id));
          resetTypingSnapshot();
          const replacement = event.key === "Backspace" || event.key === "Delete" ? "" : event.key;
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

        if (!block.unlocked && normalizedKey(event.key) === "Enter") {
          event.preventDefault();
          recordUndoSnapshot(makeHistorySnapshot(block.id));
          resetTypingSnapshot();
          const nextID = splitBlockAtCaret(block.id, currentCaretOffset());
          render(nextID, null, true);
          post("documentChanged");
          return;
        }

        const caretOffset = currentCaretOffset();
        if (!block.unlocked && shouldUnlockFromKey(event, caretOffset)) {
          const markerRange = markerSelectionRange(block);
          blocks = unlockBlock(blocks, block.id);
          event.preventDefault();
          render(block.id, markerRange);
          post("blockUnlocked", { blockID: block.id });
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
      editor.append(row);
    }

    if (focusID) {
      const target = editor.querySelector(`[data-block-id="${focusID}"] .editor-content`);
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

  function post(type, payload = {}) {
    window.webkit?.messageHandlers?.editor?.postMessage({
      type,
      markdown: serializeBlocks(blocks),
      ...payload,
    });
  }

  function updateFormattingMenu() {
    const state = selectedTextState();
    if (!state || state.start === state.end || !canFormatBlock(state.block)) {
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
    const state = selectedTextState() || lastFormattingSelection;
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
      content,
      block,
      start: Math.min(start, end),
      end: Math.max(start, end),
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
    return Boolean(block) && !block.unlocked && !isRawDisplayType(block);
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

    return parsedBlocks;
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
    return replaceBlockWithSource(sourceBlocks, id, block.visibleText);
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
    if (source.length === 0) return block({ index, source, type: "blank", visibleText: "", prefix: "", suffix: "" });
    if (inFence && !isFence(source)) return block({ index, source, type: "code", visibleText: source, prefix: "", suffix: "" });
    return parseFence(source, index)
      || parseHeading(source, index)
      || parseUnorderedList(source, index)
      || parseOrderedList(source, index)
      || parseQuote(source, index)
      || block({ index, source, type: "paragraph", visibleText: source, prefix: "", suffix: "" });
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

  function block(values) {
    return { id: `line-${values.index}`, index: values.index, marker: "", level: 0, unlocked: false, anchorID: "", ...values };
  }

  function serializeBlock(block) {
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
    if (block.unlocked || isRawDisplayType(block)) {
      element.textContent = block.visibleText;
      return;
    }
    element.innerHTML = inlineMarkdownHTML(block.visibleText);
  }

  function isRawDisplayType(block) {
    return block.type === "code" || block.type === "fence";
  }

  function inlineMarkdownHTML(value) {
    const placeholders = [];
    let html = escapeHTML(value);

    html = html.replace(/`([^`]+)`/g, (_match, code) => placeholder(placeholders, `<code>${code}</code>`));
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
    return /^(#{1,6}|[-+*]|>\s*)$/.test(source);
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
    if (key === "o" || key === "f" || key === "/" || key === "r") return "native-command";
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
