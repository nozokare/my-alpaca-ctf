import { execFileSync, spawn } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import readline from "node:readline/promises";
import { fetchAlpacaHackChallengeInfo } from "./lib/alpacahack.ts";
import { ensureGitContext, switchToBranch } from "./lib/git-helper.ts";

type Options = {
  challengeUrl: string;
  interactive: boolean;
  openInVscode: boolean;
};

type ChallengeContext = {
  challengeUrl: string;
  type: "daily" | "bside";
  date: string;
  branchName: string;
  title: string;
  slug: string;
  challengeDir: string;
  readmePath: string;
  attachments: { name: string; url: string }[];
};

function usage(): void {
  console.log(`Usage:
  node scripts/new-challenge.ts --url <challenge-url> [options]

Examples:
  node scripts/new-challenge.ts -i
  node scripts/new-challenge.ts --url https://alpacahack.com/daily-bside/challenges/uouo-fish-jail --no-open

Behavior:
  - Fetch challenge info from the given URL
  - Create/switch branch {type}-{yyyymmdd} from main
  - Create directory {yyyy-mm}/{dd}-{type}-{slug}
  - Create README.md template
  - Download handout attachments (.tar.gz is auto-extracted)
  - Create .env with CONNECT=
`);
}

function parseArgs(argv: string[]): Options {
  let challengeUrl = "";
  let interactive = false;
  let openInVscode = true;

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index] || "";
    if (arg === "--no-open") {
      openInVscode = false;
      continue;
    }
    if (arg === "-i" || arg === "--interactive") {
      interactive = true;
      continue;
    }
    if (arg === "-u" || arg === "--url") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error(`missing value for ${arg}`);
      }
      if (challengeUrl) {
        throw new Error("challenge URL must be specified only once");
      }
      challengeUrl = value;
      index += 1;
      continue;
    }
    if (arg === "-h" || arg === "--help") {
      usage();
      process.exit(0);
    }
    if (arg.startsWith("-")) {
      throw new Error(`unknown option: ${arg}`);
    }

    throw new Error("challenge URL must be passed with --url");
  }

  return { challengeUrl, interactive, openInVscode };
}

async function buildChallengeContext(
  challengeUrl: string,
): Promise<ChallengeContext> {
  const info = await fetchAlpacaHackChallengeInfo(challengeUrl);
  const pageUrl = info.pageUrl ?? challengeUrl;
  const url = new URL(pageUrl);
  url.search = ""; // Ignore query parameters for slug/type inference.
  const slug = extractSlug(url);
  const type = inferType(url);
  const date = info.released.replaceAll("-", "");

  if (!/^\d{8}$/.test(date)) {
    throw new Error(`unexpected released date format: ${info.released}`);
  }

  const yyyy = date.slice(0, 4);
  const mm = date.slice(4, 6);
  const dd = date.slice(6, 8);
  const branchName = `${type}-${date}`;
  const challengeDir = path.join(`${yyyy}-${mm}`, `${dd}-${type}-${slug}`);
  const readmePath = path.join(challengeDir, "README.md");
  return {
    challengeUrl: url.toString(),
    type,
    date,
    branchName,
    title: info.title,
    slug,
    challengeDir,
    readmePath,
    attachments: info.attachments,
  };
}

function extractSlug(url: URL): string {
  const slug = url.pathname.split("/").filter(Boolean).at(-1) ?? "";
  if (!slug) {
    throw new Error(`failed to determine slug from URL: ${url.toString()}`);
  }
  return slug;
}

function inferType(url: URL): "daily" | "bside" {
  if (url.pathname.includes("/daily-bside/")) {
    return "bside";
  }
  if (url.pathname.includes("/daily/")) {
    return "daily";
  }
  throw new Error(
    `failed to determine challenge type from URL: ${url.toString()}`,
  );
}

async function ensureChallengeDir(
  repoRoot: string,
  challengeDir: string,
): Promise<string> {
  const absoluteDir = path.join(repoRoot, challengeDir);
  await fs.mkdir(absoluteDir, { recursive: true });
  console.log(`Prepared challenge directory: ${challengeDir}`);
  return absoluteDir;
}

async function createReadme(
  challenge: ChallengeContext,
  absoluteDir: string,
): Promise<void> {
  const content = `# ${challenge.title}

${challenge.challengeUrl}

## 問題の概要

## 解法
`;

  await fs.writeFile(path.join(absoluteDir, "README.md"), content, "utf8");
  console.log(`Created README: ${challenge.readmePath}`);
}

async function writeConnectFile(absoluteDir: string): Promise<void> {
  const envPath = path.join(absoluteDir, ".env");
  await fs.writeFile(envPath, "CONNECT=\n", "utf8");
  console.log(
    `Saved connection string: ${path.relative(process.cwd(), envPath)}`,
  );
}

async function downloadAttachments(
  challenge: ChallengeContext,
  absoluteDir: string,
): Promise<void> {
  if (challenge.attachments.length === 0) {
    return;
  }

  const handoutDir = path.join(absoluteDir, "handout");
  await fs.mkdir(handoutDir, { recursive: true });

  for (const attachment of challenge.attachments) {
    const fileName = determineAttachmentFileName(
      attachment.url,
      attachment.name,
    );
    const destination = path.join(handoutDir, fileName);

    console.log(`Downloading: ${attachment.url}`);
    const response = await fetch(attachment.url, {
      signal: AbortSignal.timeout(15_000),
    });
    if (!response.ok) {
      throw new Error(
        `failed to download ${attachment.url}: ${response.status} ${response.statusText}`,
      );
    }

    const buffer = Buffer.from(await response.arrayBuffer());
    await fs.writeFile(destination, buffer);
    console.log(`Saved file: ${path.relative(process.cwd(), destination)}`);

    if (fileName.endsWith(".tar.gz")) {
      extractTarGz(destination, handoutDir);
      console.log(`Extracted to: ${path.relative(process.cwd(), handoutDir)}`);
    }
  }
}

function extractTarGz(archivePath: string, handoutDir: string): void {
  const listOutput = execFileSync("tar", ["-tzf", archivePath], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  const entries = listOutput
    .split("\n")
    .map((entry) => entry.trim())
    .filter((entry) => entry.length > 0);

  const args = ["-xzf", archivePath, "-C", handoutDir];
  if (shouldStripTopLevelDirectory(entries)) {
    args.push("--strip-components=1");
  }

  execFileSync("tar", args, {
    stdio: "inherit",
  });
}

function shouldStripTopLevelDirectory(entries: string[]): boolean {
  if (entries.length === 0) {
    return false;
  }

  const topLevels = new Set(entries.map((entry) => entry.split("/")[0]));
  if (topLevels.size !== 1) {
    return false;
  }

  const [topLevel] = [...topLevels];
  const hasNestedEntry = entries.some((entry) =>
    entry.startsWith(`${topLevel}/`),
  );
  if (!hasNestedEntry) {
    return false;
  }

  return entries.every(
    (entry) =>
      entry === topLevel ||
      entry === `${topLevel}/` ||
      entry.startsWith(`${topLevel}/`),
  );
}

function determineAttachmentFileName(
  urlText: string,
  fallbackName: string,
): string {
  try {
    const url = new URL(urlText);
    const baseName = path.posix.basename(url.pathname);
    if (baseName && baseName !== "/" && baseName !== ".") {
      return baseName;
    }
  } catch {
    // Fall back to the provided attachment name below.
  }

  const normalizedName = path.basename(fallbackName.trim());
  if (normalizedName) {
    return normalizedName;
  }

  throw new Error(`failed to determine file name for attachment: ${urlText}`);
}

async function promptForMissingOptions(options: Options): Promise<Options> {
  if (options.challengeUrl) {
    return options;
  }

  if (!options.interactive) {
    throw new Error("challenge URL is required");
  }

  if (!process.stdin.isTTY || !process.stdout.isTTY) {
    throw new Error("interactive mode requires a TTY");
  }

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  try {
    const challengeUrl = (await rl.question("Challenge URL: ")).trim();
    if (!challengeUrl) {
      throw new Error("challenge URL is required");
    }
    return { ...options, challengeUrl };
  } finally {
    rl.close();
  }
}

function openInVscode(filePaths: string[]): void {
  if (process.env.TERM_PROGRAM !== "vscode") {
    return;
  }

  if (filePaths.length === 0) {
    return;
  }

  const child = spawn("code", filePaths, {
    detached: true,
    stdio: "ignore",
  });
  child.unref();
}

async function collectFilesToOpen(absoluteDir: string): Promise<string[]> {
  const filesToOpen = [path.join(absoluteDir, "README.md")];
  const handoutDir = path.join(absoluteDir, "handout");
  const handoutFiles = await findPreferredHandoutFiles(handoutDir);
  return [...filesToOpen, ...handoutFiles];
}

async function findPreferredHandoutFiles(
  handoutDir: string,
): Promise<string[]> {
  try {
    await fs.access(handoutDir);
  } catch {
    return [];
  }

  const matchedFiles: string[] = [];
  const entries = await fs.readdir(handoutDir, {
    recursive: true,
    withFileTypes: true,
  });

  for (const entry of entries) {
    if (!entry.isFile()) {
      continue;
    }

    const relativePath = entry.parentPath
      ? path.relative(handoutDir, path.join(entry.parentPath, entry.name))
      : entry.name;
    const baseName = path.basename(relativePath);
    if (!/^(index|server|main|chal)\.(js|py|php|c)$/i.test(baseName)) {
      continue;
    }

    matchedFiles.push(path.join(handoutDir, relativePath));
  }

  matchedFiles.sort();
  return matchedFiles;
}

async function main(): Promise<void> {
  const parsedOptions = parseArgs(process.argv.slice(2));
  const options = await promptForMissingOptions(parsedOptions);
  const git = ensureGitContext();
  const challenge = await buildChallengeContext(options.challengeUrl);

  switchToBranch(git, challenge.branchName);

  const absoluteDir = await ensureChallengeDir(
    git.repoRoot,
    challenge.challengeDir,
  );
  await downloadAttachments(challenge, absoluteDir);
  await writeConnectFile(absoluteDir);
  await createReadme(challenge, absoluteDir);

  console.log("");
  console.log("Done.");
  console.log(`branch: ${challenge.branchName}`);
  console.log(`challenge: ${challenge.challengeDir}`);

  if (options.openInVscode) {
    openInVscode(await collectFilesToOpen(absoluteDir));
  }
}

await main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(message);
  process.exitCode = 1;
});
