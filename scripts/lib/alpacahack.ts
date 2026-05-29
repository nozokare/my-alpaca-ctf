import { JSDOM } from "jsdom";

export type AlpacaHackAttachment = {
  name: string;
  url: string;
};

export type AlpacaHackChallengeInfo = {
  pageUrl?: string;
  title: string | null;
  topic: string | null;
  released: string | null;
  category: string | null;
  difficulty: string | null;
  solves: number | null;
  author: string | null;
  authorUrl?: string;
  description: string | null;
  details: string[];
  attachments: AlpacaHackAttachment[];
};

export async function fetchAlpacaHackChallengeInfo(
  url: string,
): Promise<AlpacaHackChallengeInfo> {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(
      `failed to fetch ${url}: ${response.status} ${response.statusText}`,
    );
  }

  const html = await response.text();
  return parseAlpacaHackChallengeHtml(html, url);
}

export function parseAlpacaHackChallengeHtml(
  html: string,
  pageUrl?: string,
): AlpacaHackChallengeInfo {
  const dom = new JSDOM(html, pageUrl ? { url: pageUrl } : undefined);
  const { document } = dom.window;
  const challengeInfo: AlpacaHackChallengeInfo = {
    ...(pageUrl ? { pageUrl } : {}),
    title: null,
    topic: null,
    released: null,
    category: null,
    difficulty: null,
    solves: null,
    author: null,
    description: null,
    details: [],
    attachments: [],
  };

  const mainStack = document.querySelector("main.MuiStack-root");
  if (!(mainStack instanceof dom.window.HTMLElement)) {
    return challengeInfo;
  }

  const titleElement = mainStack.querySelector("h1");
  if (titleElement instanceof dom.window.HTMLHeadingElement) {
    challengeInfo.title = getNodeText(titleElement) || null;
  }

  const metaElement = mainStack.querySelector("h1 ~ p");
  if (metaElement instanceof dom.window.HTMLParagraphElement) {
    const meta = extractHeaderMeta(metaElement);
    challengeInfo.topic = meta.topic;
    challengeInfo.released = meta.released;
  }

  const sectionRoot = mainStack.querySelector("article");
  if (sectionRoot instanceof dom.window.HTMLElement) {
    challengeInfo.description = extractDescription(sectionRoot);
    challengeInfo.details = extractDetails(sectionRoot);
    challengeInfo.attachments = extractAttachments(sectionRoot, pageUrl);
  }

  const extra = extractChallengeExtras(mainStack, pageUrl);
  challengeInfo.category = extra.category;
  challengeInfo.difficulty = extra.difficulty;
  challengeInfo.solves = extra.solves;
  challengeInfo.author = extra.author;
  if (extra.authorUrl) {
    challengeInfo.authorUrl = extra.authorUrl;
  }

  return challengeInfo;
}

function extractHeaderMeta(metaElement: HTMLParagraphElement): {
  topic: string | null;
  released: string | null;
} {
  const matches = getNodeText(metaElement).match(
    /^Topic:\s*(.+?)Released:\s*(.+)$/,
  );

  const topic = matches?.at(1)?.trim() || null;
  const releasedText = matches?.at(2)?.trim() || null;
  if (!releasedText) {
    return { topic, released: null };
  }

  const releasedDate = new Date(releasedText);
  if (Number.isNaN(releasedDate.getTime())) {
    return { topic, released: null };
  }

  return { topic, released: formatDate(releasedDate) };
}

function extractChallengeExtras(
  infoBox: Element,
  pageUrl?: string,
): {
  category: string | null;
  difficulty: string | null;
  solves: number | null;
  author: string | null;
  authorUrl?: string;
} {
  const chips = [...infoBox.querySelectorAll("span.MuiChip-label")].map(
    (chip) => getNodeText(chip),
  );
  const solvesText = chips.find((text) => /\d+\s+solves?/i.test(text));
  const metaChips = chips.filter((text) => !/solves/i.test(text));
  const category = metaChips[0] ?? null;
  const difficulty = metaChips[1] ?? null;
  const authorLink = [...infoBox.querySelectorAll("a[href]")].find((anchor) => {
    const href = anchor.getAttribute("href") ?? "";
    return /^\/users\//.test(href);
  });

  const author = authorLink ? extractAuthorName(authorLink) || null : null;
  const authorUrl = authorLink
    ? (toAbsoluteUrl(authorLink.getAttribute("href") ?? "", pageUrl) ??
      undefined)
    : undefined;
  const parsedSolves = solvesText ? Number.parseInt(solvesText, 10) : Number.NaN;
  const solves = Number.isNaN(parsedSolves) ? null : parsedSolves;

  return {
    category,
    difficulty,
    solves,
    author,
    ...(authorUrl ? { authorUrl } : {}),
  };
}

function extractAuthorName(authorLink: Element): string {
  const label = authorLink.querySelector("p");
  if (label) {
    return getNodeText(label);
  }

  return getNodeText(authorLink);
}

function extractDescription(section: Element): string | null {
  return section.querySelector(":scope > p")?.textContent?.trim() || null;
}

function extractDetails(section: Element): string[] {
  return [...section.querySelectorAll(":scope > details")]
    .map((element) => getNodeText(element))
    .filter((text) => text.length > 0);
}

function extractAttachments(
  section: Element,
  pageUrl?: string,
): AlpacaHackAttachment[] {
  const pageOrigin = getOrigin(pageUrl);
  const attachments: AlpacaHackAttachment[] = [];

  for (const anchor of section.querySelectorAll("a[href]")) {
    const href = anchor.getAttribute("href");
    if (!href) {
      continue;
    }

    if (
      !anchor.hasAttribute("download") &&
      !looksLikeAttachment(anchor, href, pageOrigin)
    ) {
      continue;
    }

    const url = toAbsoluteUrl(href, pageUrl);
    if (!url) {
      continue;
    }

    const name = getNodeText(anchor);
    if (!name) {
      continue;
    }

    if (!attachments.some((attachment) => attachment.url === url)) {
      attachments.push({ name, url });
    }
  }

  return attachments;
}

function looksLikeAttachment(
  anchor: Element,
  href: string,
  pageOrigin?: string,
): boolean {
  const text = getNodeText(anchor);
  if (!text) {
    return false;
  }

  if (
    /\.(?:tar\.gz|tgz|zip|7z|rar|gz|xz|bz2|py|txt|c|cpp|cc|rs|go|java|js|ts|php|rb|pl|sh|sql|json|yaml|yml|toml|md)$/i.test(
      text,
    )
  ) {
    return true;
  }

  const url = toAbsoluteUrl(href, pageOrigin);
  if (!url) {
    return false;
  }

  const pathname = new URL(url).pathname;
  return /\.(?:tar\.gz|tgz|zip|7z|rar|gz|xz|bz2|py|txt|c|cpp|cc|rs|go|java|js|ts|php|rb|pl|sh|sql|json|yaml|yml|toml|md)$/i.test(
    pathname,
  );
}

function toAbsoluteUrl(href: string, baseUrl?: string): string | null {
  try {
    return new URL(href, normalizeBaseUrl(baseUrl)).toString();
  } catch {
    return null;
  }
}

function getOrigin(url?: string): string | undefined {
  try {
    return new URL(normalizeBaseUrl(url)).origin;
  } catch {
    return undefined;
  }
}

function normalizeBaseUrl(url?: string): string {
  if (!url) {
    return "https://alpacahack.com";
  }

  try {
    const parsed = new URL(url);
    if (parsed.protocol === "http:" || parsed.protocol === "https:") {
      return parsed.toString();
    }
  } catch {
    // fall through
  }

  return "https://alpacahack.com";
}

function getNodeText(node: Element): string {
  const ownerDocument = node.ownerDocument;
  const defaultView = ownerDocument.defaultView;
  if (!defaultView) {
    return normalizeSpace(node.textContent ?? "");
  }

  const walker = ownerDocument.createTreeWalker(
    node,
    defaultView.NodeFilter.SHOW_TEXT,
  );
  const parts: string[] = [];

  let current = walker.nextNode();
  while (current) {
    const parent = current.parentElement;
    if (parent && !parent.closest("style, script, noscript")) {
      const text = normalizeSpace(current.textContent ?? "");
      if (text) {
        parts.push(text);
      }
    }
    current = walker.nextNode();
  }

  return normalizeSpace(parts.join(" "));
}

function normalizeSpace(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

function formatDate(date: Date): string {
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, "0");
  const day = date.getDate().toString().padStart(2, "0");
  return `${year}-${month}-${day}`;
}
