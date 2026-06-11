export function parseMarkdown(markdown) {
  const lines = markdown.split("\n");
  const blocks = [];
  let inFence = false;

  lines.forEach((source, index) => {
    const block = parseLine(source, { index, inFence });
    blocks.push(block);

    if (block.type === "fence") {
      inFence = !inFence;
    }
  });

  return blocks;
}

export function serializeBlocks(blocks) {
  return blocks.map(serializeBlock).join("\n");
}

export function editVisibleText(blocks, id, visibleText) {
  return blocks.map((block) => {
    if (block.id !== id) return block;
    return {
      ...block,
      visibleText,
      source: block.prefix + visibleText + block.suffix,
    };
  });
}

export function unlockBlock(blocks, id) {
  return blocks.map((block) => {
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

export function applyUnlockedSource(blocks, id, source) {
  return blocks.map((block) => {
    if (block.id !== id) return block;
    return {
      ...parseLine(source, { index: block.index, inFence: block.type === "code" }),
      id: block.id,
    };
  });
}

export function classifyShortcut(eventLike) {
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

export function shouldUnlockFromKey(eventLike, caretOffset) {
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
