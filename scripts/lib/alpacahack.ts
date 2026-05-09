import { JSDOM } from "jsdom";

export type AlpacaHackAttachment = {
  name: string;
  url: string;
};

export type AlpacaHackChallengeInfo = {
  pageUrl?: string;
  title: string;
  topic: string;
  released: string;
  category: string;
  difficulty: string;
  solves: number;
  author: string;
  authorUrl?: string;
  description: string;
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

  const mainStack = document.querySelector("main.MuiStack-root");
  if (!(mainStack instanceof dom.window.HTMLElement)) {
    throw new Error("challenge main stack not found");
  }

  const titleElement = mainStack.querySelector("h1");
  if (!(titleElement instanceof dom.window.HTMLHeadingElement)) {
    throw new Error("challenge title element not found");
  }

  const metaElement = mainStack.querySelector("h1 ~ p");
  if (!(metaElement instanceof dom.window.HTMLParagraphElement)) {
    throw new Error("challenge metadata element not found");
  }

  const sectionRoot = mainStack.querySelector("article");
  if (!(sectionRoot instanceof dom.window.HTMLElement)) {
    throw new Error("challenge section root not found");
  }

  const meta = extractHeaderMeta(metaElement);
  const description = extractDescription(sectionRoot);
  const details = extractDetails(sectionRoot);
  const attachments = extractAttachments(sectionRoot, pageUrl);
  const extra = extractChallengeExtras(mainStack, pageUrl);

  return {
    ...(pageUrl ? { pageUrl } : {}),
    title: getNodeText(titleElement),
    topic: meta.topic,
    released: meta.released,
    category: extra.category,
    difficulty: extra.difficulty,
    solves: extra.solves,
    author: extra.author,
    ...(extra.authorUrl ? { authorUrl: extra.authorUrl } : {}),
    description,
    details,
    attachments,
  };
}

function extractHeaderMeta(metaElement: HTMLParagraphElement): {
  topic: string;
  released: string;
} {
  const matches = getNodeText(metaElement).match(
    /^Topic:\s*(.+?)Released:\s*(.+)$/,
  );

  const topic = matches?.at(1)?.trim() || "";
  const released = matches?.at(2)?.trim() || "";

  return { topic, released: formatDate(new Date(released)) };
}

function extractChallengeExtras(
  infoBox: Element,
  pageUrl?: string,
): {
  category: string;
  difficulty: string;
  solves: number;
  author: string;
  authorUrl?: string;
} {
  const chips = [...infoBox.querySelectorAll("span.MuiChip-label")].map(
    (chip) => getNodeText(chip),
  );
  const solvesText = chips.find((text) => /\d+\s+solves?/i.test(text));
  const metaChips = chips.filter((text) => !/solves/i.test(text));
  const category = metaChips[0];
  const difficulty = metaChips[1];
  const authorLink = [...infoBox.querySelectorAll("a[href]")].find((anchor) => {
    const href = anchor.getAttribute("href") ?? "";
    return /^\/users\//.test(href);
  });

  const author = authorLink ? extractAuthorName(authorLink) : "";
  const authorUrl = authorLink
    ? (toAbsoluteUrl(authorLink.getAttribute("href") ?? "", pageUrl) ??
      undefined)
    : undefined;
  const solves = solvesText ? Number.parseInt(solvesText, 10) : Number.NaN;

  if (!category || !difficulty || !author || Number.isNaN(solves)) {
    throw new Error("failed to parse challenge extra metadata");
  }

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

function extractDescription(section: Element): string {
  return section.querySelector(":scope > p")?.textContent || "";
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
  const walker = ownerDocument.createTreeWalker(
    node,
    ownerDocument.defaultView!.NodeFilter.SHOW_TEXT,
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
