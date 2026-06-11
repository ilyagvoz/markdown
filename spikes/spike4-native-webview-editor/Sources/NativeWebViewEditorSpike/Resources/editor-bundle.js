(() => {
  const initialMarkdown = `# Candidate A Editor

This paragraph is editable without changing presentation.

- A list item keeps its marker.
- Another item can be edited.

> Quotes keep their marker.

\`\`\`swift
let value = 1
\`\`\`
`;

  let blocks = parseMarkdown(initialMarkdown);
  let pendingCommitTimer = null;
  let pendingMarkerSelection = null;

  const editor = document.querySelector("[data-editor]");
  const status = document.querySelector("[data-status]");

  render();
  post("ready");

  function render(focusID = null, selectionRange = null) {
    editor.innerHTML = "";

    for (const block of blocks) {
      const row = document.createElement("div");
      row.className = `editor-block editor-block-${block.type}`;
      row.dataset.blockId = block.id;
      row.dataset.type = block.type;

      const marker = document.createElement("span");
      marker.className = "editor-marker";
      marker.textContent = markerText(block);

      const content = document.createElement("div");
      content.className = "editor-content";
      content.contentEditable = "true";
      content.spellcheck = true;
      content.textContent = block.visibleText;
      content.setAttribute("aria-label", `${block.type} line ${block.index + 1}`);

      content.addEventListener("input", () => {
        if (block.unlocked) {
          blocks = updateUnlockedDraft(blocks, block.id, content.textContent);
          scheduleUnlockedCommit(block.id);
        } else {
          blocks = editVisibleText(blocks, block.id, content.textContent);
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

        if (route !== "editor") {
          event.preventDefault();
          status.textContent = `Shortcut routed to ${route}: ${event.key}`;
          post("shortcut", { key: event.key, route });
          return;
        }

        if (block.unlocked && pendingMarkerSelection?.id === block.id && isMarkerReplacementKey(event)) {
          event.preventDefault();
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
          clearPendingMarkerSelection();
          blocks = commitUnlockedSource(blocks, block.id);
          render(block.id);
          post("documentChanged");
          return;
        }

        const caretOffset = currentCaretOffset();
        if (!block.unlocked && shouldUnlockFromKey(event, caretOffset)) {
          const markerRange = markerSelectionRange(block);
          blocks = unlockBlock(blocks, block.id);
          status.textContent = `Unlocked Markdown marker on line ${block.index + 1}`;
          event.preventDefault();
          render(block.id, markerRange);
          post("blockUnlocked", { blockID: block.id });
        }
      });

      content.addEventListener("blur", () => {
        clearPendingCommit();
        clearPendingMarkerSelection();
        const current = findBlock(block.id);
        if (!current?.unlocked) return;
        blocks = commitUnlockedSource(blocks, block.id);
        render();
        post("documentChanged");
      });

      row.append(marker, content);
      editor.append(row);
    }

    post("documentChanged");

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
      } else {
        clearPendingMarkerSelection();
        moveCaretToStart(target);
      }
    }
  }

  function post(type, payload = {}) {
    const message = {
      type,
      markdown: serializeBlocks(blocks),
      ...payload,
    };

    window.webkit?.messageHandlers?.editor?.postMessage(message);
    if (status) status.textContent = statusText(message);
  }

  function statusText(message) {
    switch (message.type) {
      case "ready":
        return "Native bridge ready.";
      case "documentChanged":
        return "Document state synced to Swift.";
      case "blockUnlocked":
        return "Raw marker selected. Type a replacement to apply.";
      case "saveRequested":
        return "Save routed to Swift.";
      case "shortcut":
        return `Shortcut routed to ${message.route}.`;
      default:
        return "Ready.";
    }
  }

  function markerText(block) {
    if (block.unlocked) return "raw";
    switch (block.type) {
      case "heading":
        return "#".repeat(block.level);
      case "unordered-list":
        return block.marker;
      case "ordered-list":
        return block.marker;
      case "quote":
        return ">";
      case "fence":
        return block.marker;
      case "code":
        return "code";
      default:
        return "";
    }
  }

  function currentCaretOffset() {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return 0;
    return selection.getRangeAt(0).startOffset;
  }

  function moveCaretToStart(element) {
    if (!element) return;
    const range = document.createRange();
    range.selectNodeContents(element);
    range.collapse(true);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
  }

  window.nativeEditorSpike = {
    serialized() {
      return serializeBlocks(blocks);
    },
    editLine(id, visibleText) {
      blocks = editVisibleText(blocks, id, visibleText);
      render(id);
      post("documentChanged");
      return serializeBlocks(blocks);
    },
    unlockLine(id) {
      const block = findBlock(id);
      blocks = unlockBlock(blocks, id);
      render(id, block ? markerSelectionRange(block) : null);
      post("blockUnlocked", { blockID: id });
      return serializeBlocks(blocks);
    },
    rawLine(id, source) {
      blocks = updateUnlockedDraft(blocks, id, source);
      blocks = commitUnlockedSource(blocks, id);
      render(id);
      post("documentChanged");
      return serializeBlocks(blocks);
    },
    blockType(id) {
      return findBlock(id)?.type ?? "";
    },
    marker(id) {
      const block = findBlock(id);
      return block ? markerText(block) : "";
    },
    isUnlocked(id) {
      return Boolean(findBlock(id)?.unlocked);
    },
    selectedText() {
      const nativeSelection = window.getSelection()?.toString() ?? "";
      if (nativeSelection) return nativeSelection;
      if (!pendingMarkerSelection) return "";
      const block = findBlock(pendingMarkerSelection.id);
      if (!block) return "";
      return block.visibleText.slice(pendingMarkerSelection.start, pendingMarkerSelection.end);
    },
    replaceSelectedText(text) {
      const active = document.activeElement;
      let target = active?.classList?.contains("editor-content") ? active : null;
      const selection = window.getSelection();
      let start = 0;
      let end = 0;

      if (selection && selection.rangeCount > 0 && selection.toString()) {
        const range = selection.getRangeAt(0);
        start = range.startOffset;
        end = range.endOffset;
      } else if (pendingMarkerSelection) {
        target = editor.querySelector(`[data-block-id="${pendingMarkerSelection.id}"] .editor-content`);
        start = pendingMarkerSelection.start;
        end = pendingMarkerSelection.end;
      }

      if (!target) return serializeBlocks(blocks);
      replaceRangeInContent(target, start, end, text);
      const blockID = target.closest("[data-block-id]")?.dataset.blockId;
      clearPendingMarkerSelection();
      if (blockID) {
        blocks = updateUnlockedDraft(blocks, blockID, target.textContent);
        scheduleUnlockedCommit(blockID);
        post("documentChanged");
      }
      return serializeBlocks(blocks);
    },
    commitLine(id) {
      clearPendingCommit();
      blocks = commitUnlockedSource(blocks, id);
      render(id);
      post("documentChanged");
      return serializeBlocks(blocks);
    },
    focusLine(id) {
      const target = editor.querySelector(`[data-block-id="${id}"] .editor-content`);
      target?.focus();
    },
  };

  function parseMarkdown(markdown) {
    const lines = markdown.split("\n");
    const parsedBlocks = [];
    let inFence = false;

    lines.forEach((source, index) => {
      const parsed = parseLine(source, { index, inFence });
      parsedBlocks.push(parsed);

      if (parsed.type === "fence") {
        inFence = !inFence;
      }
    });

    return parsedBlocks;
  }

  function serializeBlocks(sourceBlocks) {
    return sourceBlocks.map(serializeBlock).join("\n");
  }

  function editVisibleText(sourceBlocks, id, visibleText) {
    return sourceBlocks.map((block) => {
      if (block.id !== id) return block;
      return {
        ...block,
        visibleText,
        source: block.prefix + visibleText + block.suffix,
      };
    });
  }

  function unlockBlock(sourceBlocks, id) {
    return sourceBlocks.map((block) => {
      if (block.id !== id) return block;
      return {
        ...block,
        unlocked: true,
        visibleText: serializeBlock(block),
        prefix: "",
        suffix: "",
      };
    });
  }

  function applyUnlockedSource(sourceBlocks, id, source) {
    return sourceBlocks.map((block) => {
      if (block.id !== id) return block;
      return {
        ...parseLine(source, { index: block.index, inFence: block.type === "code" }),
        id: block.id,
      };
    });
  }

  function updateUnlockedDraft(sourceBlocks, id, source) {
    return sourceBlocks.map((block) => {
      if (block.id !== id) return block;
      return {
        ...block,
        source,
        visibleText: source,
        prefix: "",
        suffix: "",
        unlocked: true,
      };
    });
  }

  function commitUnlockedSource(sourceBlocks, id) {
    const block = sourceBlocks.find((candidate) => candidate.id === id);
    if (!block) return sourceBlocks;
    return applyUnlockedSource(sourceBlocks, id, block.visibleText);
  }

  function findBlock(id) {
    return blocks.find((block) => block.id === id);
  }

  function markerSelectionRange(block) {
    const source = serializeBlock(block);
    const leadingLength = source.match(/^\s*/)?.[0]?.length ?? 0;
    const markerLength = markerTokenLength(block);
    return {
      start: leadingLength,
      end: leadingLength + markerLength,
    };
  }

  function markerTokenLength(block) {
    switch (block.type) {
      case "heading":
        return block.level;
      case "unordered-list":
      case "ordered-list":
      case "fence":
        return block.marker.length;
      case "quote":
        return 1;
      default:
        return 0;
    }
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

  function scheduleUnlockedCommit(id) {
    clearPendingCommit();
    pendingCommitTimer = window.setTimeout(() => {
      pendingCommitTimer = null;
      const current = findBlock(id);
      if (!current?.unlocked) return;
      blocks = commitUnlockedSource(blocks, id);
      render(id);
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

  function replaceRangeInContent(element, start, end, replacement) {
    const value = element.textContent;
    const safeStart = Math.max(0, Math.min(start, value.length));
    const safeEnd = Math.max(safeStart, Math.min(end, value.length));
    element.textContent = value.slice(0, safeStart) + replacement + value.slice(safeEnd);
    setTextSelection(element, safeStart + replacement.length, safeStart + replacement.length);
  }

  function isMarkerReplacementKey(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return false;
    return event.key.length === 1 || event.key === "Backspace" || event.key === "Delete";
  }

  function classifyShortcut(eventLike) {
    const meta = Boolean(eventLike.metaKey);
    const key = normalizedKey(eventLike.key);

    if (!meta) return "editor";
    if (["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(key)) {
      return "native-navigation";
    }
    if (key === "o" || key === "f" || key === "/" || key === "r") {
      return "native-command";
    }
    if (key === "s") {
      return "save";
    }
    return "editor";
  }

  function shouldUnlockFromKey(eventLike, caretOffset) {
    return normalizedKey(eventLike.key) === "ArrowLeft" && caretOffset === 0 && !eventLike.metaKey;
  }

  function parseLine(source, { index, inFence }) {
    if (source.length === 0) {
      return block({ index, source, type: "blank", visibleText: "", prefix: "", suffix: "" });
    }

    if (inFence && !isFence(source)) {
      return block({ index, source, type: "code", visibleText: source, prefix: "", suffix: "" });
    }

    const fence = parseFence(source, index);
    if (fence) return fence;

    const heading = parseHeading(source, index);
    if (heading) return heading;

    const unordered = parseUnorderedList(source, index);
    if (unordered) return unordered;

    const ordered = parseOrderedList(source, index);
    if (ordered) return ordered;

    const quote = parseQuote(source, index);
    if (quote) return quote;

    return block({ index, source, type: "paragraph", visibleText: source, prefix: "", suffix: "" });
  }

  function parseFence(source, index) {
    const [, leading = "", marker = "", language = ""] = source.match(/^(\s*)(```|~~~)(.*)$/) ?? [];
    if (!marker) return null;
    return block({
      index,
      source,
      type: "fence",
      marker,
      visibleText: language.trim(),
      prefix: leading + marker,
      suffix: "",
    });
  }

  function parseHeading(source, index) {
    const [, leading = "", marker = "", body = ""] = source.match(/^(\s{0,3})(#{1,6})\s+(.*)$/) ?? [];
    if (!marker) return null;
    const visibleText = body.replace(/\s+#+\s*$/, "");
    const suffix = body.slice(visibleText.length);
    return block({
      index,
      source,
      type: "heading",
      level: marker.length,
      visibleText,
      prefix: leading + marker + " ",
      suffix,
    });
  }

  function parseUnorderedList(source, index) {
    const [, leading = "", marker = "", body = ""] = source.match(/^(\s*)([-+*])\s+(.*)$/) ?? [];
    if (!marker) return null;
    return block({
      index,
      source,
      type: "unordered-list",
      marker,
      visibleText: body,
      prefix: leading + marker + " ",
      suffix: "",
    });
  }

  function parseOrderedList(source, index) {
    const [, leading = "", marker = "", body = ""] = source.match(/^(\s*)(\d+[.)])\s+(.*)$/) ?? [];
    if (!marker) return null;
    return block({
      index,
      source,
      type: "ordered-list",
      marker,
      visibleText: body,
      prefix: leading + marker + " ",
      suffix: "",
    });
  }

  function parseQuote(source, index) {
    const [, leading = "", body = ""] = source.match(/^(\s*)>\s?(.*)$/) ?? [];
    if (!source.trimStart().startsWith(">")) return null;
    return block({
      index,
      source,
      type: "quote",
      visibleText: body,
      prefix: leading + "> ",
      suffix: "",
    });
  }

  function block(values) {
    return {
      id: `line-${values.index}`,
      index: values.index,
      marker: "",
      level: 0,
      unlocked: false,
      ...values,
    };
  }

  function serializeBlock(block) {
    if (block.unlocked) return block.visibleText;
    return block.prefix + block.visibleText + block.suffix;
  }

  function isFence(source) {
    return /^\s*(```|~~~)/.test(source);
  }

  function normalizedKey(key) {
    if (!key) return "";
    return key.length === 1 ? key.toLowerCase() : key;
  }
})();
