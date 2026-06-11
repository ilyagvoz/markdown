import {
  applyUnlockedSource,
  classifyShortcut,
  editVisibleText,
  parseMarkdown,
  serializeBlocks,
  shouldUnlockFromKey,
  unlockBlock,
} from "./editor-core.mjs";

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
const source = document.querySelector("[data-source]");
const status = document.querySelector("[data-status]");

render();

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
        blocks = applyUnlockedSource(blocks, block.id, content.textContent);
      } else {
        blocks = editVisibleText(blocks, block.id, content.textContent);
      }
      updateSource();
    });

    content.addEventListener("keydown", (event) => {
      const route = classifyShortcut(event);
      if (route !== "editor") {
        status.textContent = `Shortcut routed to ${route}: ${event.key}`;
        event.preventDefault();
        return;
      }

      const caretOffset = currentCaretOffset();
      if (!block.unlocked && shouldUnlockFromKey(event, caretOffset)) {
        blocks = unlockBlock(blocks, block.id);
        status.textContent = `Unlocked Markdown marker on line ${block.index + 1}`;
        event.preventDefault();
        render(block.id);
      }
    });

    row.append(marker, content);
    editor.append(row);
  }

  updateSource();

  if (focusID) {
    const target = editor.querySelector(`[data-block-id="${focusID}"] .editor-content`);
    target?.focus();
  }
}

function updateSource() {
  source.textContent = serializeBlocks(blocks);
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
