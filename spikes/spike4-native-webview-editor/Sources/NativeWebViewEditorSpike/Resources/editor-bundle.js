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

  const editor = document.querySelector("[data-editor]");
  const status = document.querySelector("[data-status]");

  render();
  post("ready");

  function render(focusID = null) {
    editor.innerHTML = "";

    for (const block of blocks) {
      const row = document.createElement("div");
      row.className = `editor-block editor-block-${block.type}`;
      row.dataset.blockID = block.id;
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

        if (block.unlocked && normalizedKey(event.key) === "Enter") {
          event.preventDefault();
          blocks = commitUnlockedSource(blocks, block.id);
          render(block.id);
          post("documentChanged");
          return;
        }

        const caretOffset = currentCaretOffset();
        if (!block.unlocked && shouldUnlockFromKey(event, caretOffset)) {
          blocks = unlockBlock(blocks, block.id);
          status.textContent = `Unlocked Markdown marker on line ${block.index + 1}`;
          event.preventDefault();
          render(block.id);
          post("blockUnlocked", { blockID: block.id });
        }
      });

      content.addEventListener("blur", () => {
        const current = findBlock(block.id);
        if (!current?.unlocked) return;
        blocks = commitUnlockedSource(blocks, block.id);
        render();
        post("documentChanged");
      });

      row.append(marker, content);
      editor.append(row);
    }

    if (focusID) {
      const target = editor.querySelector(`[data-block-id="${focusID}"] .editor-content`);
      target?.focus();
      moveCaretToStart(target);
    }

    post("documentChanged");
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
        return "Raw marker unlocked. Press Return or leave the line to apply.";
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
      blocks = unlockBlock(blocks, id);
      render(id);
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
