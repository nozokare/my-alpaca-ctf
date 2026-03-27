import { execFileSync } from "node:child_process";

export type GitContext = {
  repoRoot: string;
  currentBranch: string;
  mainRef: string;
};

export function ensureGitContext(): GitContext {
  let repoRoot = "";
  try {
    repoRoot = runGit(["rev-parse", "--show-toplevel"]);
  } catch {
    throw new Error("this script must be run inside a git repository");
  }

  const currentBranch = runGit(["branch", "--show-current"], repoRoot);
  const hasChanges = hasDirtyWorktree(repoRoot);
  const mainRef = resolveMainRef(repoRoot);

  if (hasChanges) {
    throw new Error("worktree should be clean to create/switch branches");
  }

  return { repoRoot, currentBranch, mainRef };
}

export function switchToBranch(git: GitContext, branchName: string): void {
  if (git.currentBranch === branchName) {
    console.log(`Already on branch: ${branchName}`);
    return;
  }

  if (
    hasGitRef(git.repoRoot, [
      "show-ref",
      "--verify",
      "--quiet",
      `refs/heads/${branchName}`,
    ])
  ) {
    console.log(`Switching to existing branch: ${branchName}`);
    execFileSync("git", ["switch", branchName], {
      cwd: git.repoRoot,
      stdio: "inherit",
    });
    return;
  }

  console.log(`Creating branch ${branchName} from ${git.mainRef}`);
  execFileSync("git", ["switch", "-c", branchName, git.mainRef], {
    cwd: git.repoRoot,
    stdio: "inherit",
  });
}

function runGit(args: string[], cwd?: string): string {
  return execFileSync("git", args, {
    cwd,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
}

function hasDirtyWorktree(repoRoot: string): boolean {
  try {
    execFileSync("git", ["diff", "--quiet"], {
      cwd: repoRoot,
      stdio: "ignore",
    });
    execFileSync("git", ["diff", "--cached", "--quiet"], {
      cwd: repoRoot,
      stdio: "ignore",
    });
    return false;
  } catch {
    return true;
  }
}

function resolveMainRef(repoRoot: string): string {
  if (
    hasGitRef(repoRoot, ["show-ref", "--verify", "--quiet", "refs/heads/main"])
  ) {
    return "main";
  }
  if (
    hasGitRef(repoRoot, [
      "show-ref",
      "--verify",
      "--quiet",
      "refs/remotes/origin/main",
    ])
  ) {
    return "origin/main";
  }
  throw new Error("main branch was not found (local main or origin/main)");
}

function hasGitRef(repoRoot: string, args: string[]): boolean {
  try {
    execFileSync("git", args, { cwd: repoRoot, stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}
