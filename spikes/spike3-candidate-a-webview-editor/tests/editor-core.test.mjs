import assert from "node:assert/strict";
import test from "node:test";
import {
  applyUnlockedSource,
  classifyShortcut,
  editVisibleText,
  parseMarkdown,
  serializeBlocks,
  shouldUnlockFromKey,
  unlockBlock,
} from "../web/editor-core.mjs";

test("round-trips common block shapes without edits", () => {
  const markdown = `# Guide

Paragraph.

- Item
1. Ordered
> Quote

\`\`\`swift
let value = 1
\`\`\``;

  const blocks = parseMarkdown(markdown);

  assert.equal(serializeBlocks(blocks), markdown);
});

test("ordinary visible text edits preserve Markdown presentation markers", () => {
  let blocks = parseMarkdown(`# Old
- Old item
> Old quote
\`\`\`swift
let value = 1
\`\`\``);

  blocks = editVisibleText(blocks, "line-0", "New");
  blocks = editVisibleText(blocks, "line-1", "New item");
  blocks = editVisibleText(blocks, "line-2", "New quote");
  blocks = editVisibleText(blocks, "line-4", "let value = 2");

  assert.equal(
    serializeBlocks(blocks),
    `# New
- New item
> New quote
\`\`\`swift
let value = 2
\`\`\``,
  );
});

test("left arrow at the beginning of a locked block unlocks raw Markdown source", () => {
  let blocks = parseMarkdown("## Heading");

  assert.equal(shouldUnlockFromKey({ key: "ArrowLeft", metaKey: false }, 0), true);
  blocks = unlockBlock(blocks, "line-0");

  assert.equal(blocks[0].unlocked, true);
  assert.equal(blocks[0].visibleText, "## Heading");
  assert.equal(serializeBlocks(blocks), "## Heading");
});

test("unlocked source can intentionally change presentation type", () => {
  let blocks = parseMarkdown("## Heading");
  blocks = unlockBlock(blocks, "line-0");
  blocks = applyUnlockedSource(blocks, "line-0", "- Heading");

  assert.equal(blocks[0].type, "unordered-list");
  assert.equal(blocks[0].visibleText, "Heading");
  assert.equal(serializeBlocks(blocks), "- Heading");
});

test("app-level shortcuts are classified for native routing", () => {
  assert.equal(classifyShortcut({ key: "ArrowUp", metaKey: true }), "native-navigation");
  assert.equal(classifyShortcut({ key: "ArrowDown", metaKey: true }), "native-navigation");
  assert.equal(classifyShortcut({ key: "ArrowLeft", metaKey: true }), "native-navigation");
  assert.equal(classifyShortcut({ key: "ArrowRight", metaKey: true }), "native-navigation");
  assert.equal(classifyShortcut({ key: "o", metaKey: true }), "native-command");
  assert.equal(classifyShortcut({ key: "f", metaKey: true }), "native-command");
  assert.equal(classifyShortcut({ key: "/", metaKey: true }), "native-command");
  assert.equal(classifyShortcut({ key: "r", metaKey: true }), "native-command");
  assert.equal(classifyShortcut({ key: "s", metaKey: true }), "save");
  assert.equal(classifyShortcut({ key: "a", metaKey: false }), "editor");
});
