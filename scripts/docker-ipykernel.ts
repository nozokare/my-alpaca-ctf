import { spawn } from "node:child_process";
import { randomUUID } from "node:crypto";
import fs from "node:fs/promises";
import net from "node:net";
import path from "node:path";

type AddOptions = {
  image: string;
  kernelName: string;
  displayName: string;
  pythonCommand: string;
  containerKernelName: string;
};

type RunOptions = {
  image: string;
  connectionFile: string;
  kernelArgv: string[];
  kernelEnv: Record<string, string>;
};

type InvestOptions = {
  image: string;
  pythonCommand: string;
};

type ListOptions = {
  helpOnly: boolean;
};

type ContainerKernelSpec = {
  resource_dir?: string;
  spec: {
    argv: string[];
    display_name: string;
    language?: string;
    env?: Record<string, string>;
    interrupt_mode?: string;
    metadata?: Record<string, unknown>;
  };
};

type ContainerKernelSpecList = {
  kernelspecs: Record<string, ContainerKernelSpec>;
};

type JupyterPaths = {
  data: string[];
};

type ConnectionInfo = {
  ip: string;
  shell_port: number;
  iopub_port: number;
  stdin_port: number;
  control_port: number;
  hb_port: number;
  transport?: string;
  signature_scheme?: string;
  key?: string;
  kernel_name?: string;
};

function usage(): void {
  console.log(`Usage:
  node scripts/docker-ipykernel.ts <subcommand> [options]

Subcommands:
  add                           Create kernelspec in the local Jupyter kernels directory
  list                          List kernelspecs visible to the local jupyter command
  run                           Launch ipykernel in Docker using connection_file
  invest                        List kernelspecs available in a Docker image

Add options:
  --image <image>               Docker image with ipykernel preinstalled (required)
  --kernel <kernel>             Kernelspec name installed in container (required)
  --display-name <name>         Jupyter display name (required)
  --name <kernel-name>          Local kernelspec name (default: docker-<image>-<kernel>)
  --python <python command>     Python command in container (default: python)

Run options:
  --image <image>               Docker image with ipykernel preinstalled (required)
  --connection-file <path>      Jupyter connection file path (required)
  -f <path>                     Alias of --connection-file
  --kernel-argv-json <json>     JSON array for the container launch argv (required)
  --kernel-env-json <json>      JSON object for container environment variables

Invest options:
  --image <image>               Docker image to investigate (required)
  --python <python command>     Python command in container (default: python)

List options:
  (no options)

Options:
  -h, --help                    Show this help

Examples:
  node scripts/docker-ipykernel.ts list
  node scripts/docker-ipykernel.ts invest --image sagemath/sagemath --python "sage -python"
  npm run jupyter:kernel:add -- --image sagemath/sagemath --python "sage -python" --kernel sagemath --display-name "SageMath"
  node scripts/docker-ipykernel.ts run --image python:3.12 -connection-file /tmp/kernel.json --kernel-argv-json '["python","-m","ipykernel_launcher"]'
`);
}

function parseListArgs(argv: string[]): ListOptions {
  for (const arg of argv) {
    if (arg === "-h" || arg === "--help") {
      usage();
      process.exit(0);
    }

    throw new Error(`unknown option for list: ${arg}`);
  }

  return { helpOnly: false };
}

function parseAddArgs(argv: string[]): AddOptions {
  let image = "";
  let kernelName = "";
  let displayName = "";
  let pythonCommand = "python";
  let containerKernelName = "";

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index] ?? "";
    if (arg === "--image") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error("missing value for --image");
      }
      image = value;
      index += 1;
      continue;
    }

    if (arg === "--name") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error("missing value for --name");
      }
      kernelName = value;
      index += 1;
      continue;
    }

    if (arg === "--display-name") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error("missing value for --display-name");
      }
      displayName = value;
      index += 1;
      continue;
    }

    if (arg === "--python") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error("missing value for --python");
      }
      pythonCommand = value;
      index += 1;
      continue;
    }

    if (arg === "--kernel") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error("missing value for --kernel");
      }
      containerKernelName = value;
      index += 1;
      continue;
    }

    if (arg === "-h" || arg === "--help") {
      usage();
      process.exit(0);
    }

    throw new Error(`unknown option for add: ${arg}`);
  }

  if (!image) {
    throw new Error("--image is required");
  }

  if (!containerKernelName) {
    throw new Error("--kernel is required");
  }

  if (!displayName) {
    throw new Error("--display-name is required");
  }

  const resolvedKernelName =
    kernelName || defaultKernelName(image, containerKernelName);

  return {
    image,
    kernelName: resolvedKernelName,
    displayName,
    pythonCommand,
    containerKernelName,
  };
}

function parseInvestArgs(argv: string[]): InvestOptions {
  let image = "";
  let pythonCommand = "python";

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index] ?? "";
    if (arg === "--image") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error("missing value for --image");
      }
      image = value;
      index += 1;
      continue;
    }

    if (arg === "--python") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error("missing value for --python");
      }
      pythonCommand = value;
      index += 1;
      continue;
    }

    if (arg === "-h" || arg === "--help") {
      usage();
      process.exit(0);
    }

    throw new Error(`unknown option for invest: ${arg}`);
  }

  if (!image) {
    throw new Error("--image is required");
  }

  return { image, pythonCommand };
}

function parseRunArgs(argv: string[]): RunOptions {
  let image = "";
  let connectionFile = "";
  let kernelArgvJson = "";
  let kernelEnvJson = "{}";

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index] ?? "";
    if (arg === "--image") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error("missing value for --image");
      }
      image = value;
      index += 1;
      continue;
    }

    if (arg === "--kernel-argv-json") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error("missing value for --kernel-argv-json");
      }
      kernelArgvJson = value;
      index += 1;
      continue;
    }

    if (arg === "--connection-file" || arg === "-f") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error(`missing value for ${arg}`);
      }
      connectionFile = value;
      index += 1;
      continue;
    }

    if (arg === "--kernel-env-json") {
      const value = argv[index + 1];
      if (!value) {
        throw new Error("missing value for --kernel-env-json");
      }
      kernelEnvJson = value;
      index += 1;
      continue;
    }

    if (arg === "-h" || arg === "--help") {
      usage();
      process.exit(0);
    }

    throw new Error(`unknown option for run: ${arg}`);
  }

  if (!image) {
    throw new Error("--image is required");
  }

  if (!connectionFile) {
    throw new Error("--connection-file is required");
  }

  if (!kernelArgvJson) {
    throw new Error("--kernel-argv-json is required");
  }

  let kernelArgvValue: unknown;
  try {
    kernelArgvValue = JSON.parse(kernelArgvJson) as unknown;
  } catch {
    throw new Error("--kernel-argv-json must be valid JSON");
  }

  let kernelEnvValue: unknown;
  try {
    kernelEnvValue = JSON.parse(kernelEnvJson) as unknown;
  } catch {
    throw new Error("--kernel-env-json must be valid JSON");
  }

  return {
    image,
    connectionFile,
    kernelArgv: asStringArray(kernelArgvValue, "--kernel-argv-json"),
    kernelEnv: asStringRecord(kernelEnvValue, "--kernel-env-json"),
  };
}

function defaultKernelName(image: string, kernel: string): string {
  const imagePart = image.replace(/[^a-zA-Z0-9._-]+/g, "-");
  const kernelPart = kernel.replace(/[^a-zA-Z0-9._-]+/g, "-");
  return `docker-${imagePart}-${kernelPart}`;
}

function assertKernelName(value: string): void {
  if (!/^[a-zA-Z0-9._-]+$/.test(value)) {
    throw new Error(
      "kernel name must match /^[a-zA-Z0-9._-]+$/ for Jupyter kernelspec directories",
    );
  }
}

function asConnectionInfo(value: unknown): ConnectionInfo {
  if (!value || typeof value !== "object") {
    throw new Error("connection file must be a JSON object");
  }

  const info = value as Partial<ConnectionInfo>;
  const requiredPorts: (keyof ConnectionInfo)[] = [
    "shell_port",
    "iopub_port",
    "stdin_port",
    "control_port",
    "hb_port",
  ];

  for (const key of requiredPorts) {
    if (typeof info[key] !== "number") {
      throw new Error(`connection file is missing numeric ${String(key)}`);
    }
  }

  if (typeof info.ip !== "string" || info.ip.length === 0) {
    throw new Error("connection file is missing string ip");
  }

  return info as ConnectionInfo;
}

function asStringArray(value: unknown, label: string): string[] {
  if (
    !Array.isArray(value) ||
    value.some((entry) => typeof entry !== "string")
  ) {
    throw new Error(`${label} must be a JSON array of strings`);
  }

  if (value.length === 0) {
    throw new Error(`${label} must not be empty`);
  }

  return value;
}

function asStringRecord(value: unknown, label: string): Record<string, string> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${label} must be a JSON object`);
  }

  const entries = Object.entries(value);
  if (entries.some(([, entryValue]) => typeof entryValue !== "string")) {
    throw new Error(`${label} must be a JSON object with string values`);
  }

  return Object.fromEntries(entries) as Record<string, string>;
}

function asContainerKernelSpecList(value: unknown): ContainerKernelSpecList {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("kernelspec output must be a JSON object");
  }

  const kernelspecs = (value as { kernelspecs?: unknown }).kernelspecs;
  if (
    !kernelspecs ||
    typeof kernelspecs !== "object" ||
    Array.isArray(kernelspecs)
  ) {
    throw new Error("kernelspec output is missing a kernelspecs object");
  }

  const normalized: Record<string, ContainerKernelSpec> = {};
  for (const [name, entry] of Object.entries(kernelspecs)) {
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) {
      throw new Error(`kernelspec '${name}' is invalid`);
    }

    const spec = (entry as { spec?: unknown }).spec;
    if (!spec || typeof spec !== "object" || Array.isArray(spec)) {
      throw new Error(`kernelspec '${name}' is missing spec`);
    }

    const argv = asStringArray(
      (spec as { argv?: unknown }).argv,
      `kernelspec '${name}' argv`,
    );
    const displayName = (spec as { display_name?: unknown }).display_name;
    if (typeof displayName !== "string" || displayName.length === 0) {
      throw new Error(`kernelspec '${name}' is missing display_name`);
    }

    const language = (spec as { language?: unknown }).language;
    const env = (spec as { env?: unknown }).env;
    const interruptMode = (spec as { interrupt_mode?: unknown }).interrupt_mode;
    const metadata = (spec as { metadata?: unknown }).metadata;

    normalized[name] = {
      ...(typeof (entry as { resource_dir?: unknown }).resource_dir === "string"
        ? { resource_dir: (entry as { resource_dir: string }).resource_dir }
        : {}),
      spec: {
        argv,
        display_name: displayName,
        ...(typeof language === "string" ? { language } : {}),
        ...(env === undefined
          ? {}
          : { env: asStringRecord(env, `kernelspec '${name}' env`) }),
        ...(typeof interruptMode === "string"
          ? { interrupt_mode: interruptMode }
          : {}),
        ...(metadata && typeof metadata === "object" && !Array.isArray(metadata)
          ? { metadata: metadata as Record<string, unknown> }
          : {}),
      },
    };
  }

  return { kernelspecs: normalized };
}

function decodeFileUriIfNeeded(value: string): string {
  if (!value.startsWith("file://")) {
    return value;
  }

  try {
    return new URL(value).pathname;
  } catch {
    return value;
  }
}

function detectNotebookPath(): string | null {
  const candidates = [
    process.env.VSCODE_NOTEBOOK_FILE,
    process.env.JPY_SESSION_NAME,
    process.env.IPYKERNEL_NOTEBOOK_FILE,
  ];

  for (const candidate of candidates) {
    if (!candidate) {
      continue;
    }

    const decoded = decodeFileUriIfNeeded(candidate.trim());
    if (!decoded) {
      continue;
    }

    const maybePath = path.isAbsolute(decoded)
      ? decoded
      : path.resolve(process.cwd(), decoded);

    if (maybePath.endsWith(".ipynb")) {
      return maybePath;
    }
  }

  return null;
}

function isWindowsAbsolutePath(value: string): boolean {
  return /^[a-zA-Z]:[\\/]/.test(value);
}

function toHostPath(containerPath: string, repoRoot: string): string {
  const hostRoot = process.env.HOST_DIR;
  if (!hostRoot || hostRoot.length === 0) {
    return containerPath;
  }

  const relative = path.relative(repoRoot, containerPath);
  const isInsideRepo =
    relative.length === 0 ||
    (!relative.startsWith("..") && !path.isAbsolute(relative));

  if (!isInsideRepo) {
    throw new Error(
      `path ${containerPath} is outside repository root ${repoRoot}; cannot map to host path with HOST_DIR`,
    );
  }

  if (relative.length === 0) {
    return hostRoot;
  }

  if (isWindowsAbsolutePath(hostRoot)) {
    const normalizedRelative = relative.split(path.sep).join("\\");
    return `${hostRoot.replace(/[\\/]+$/, "")}\\${normalizedRelative}`;
  }

  const normalizedRelative = relative.split(path.sep).join("/");
  return `${hostRoot.replace(/[\\/]+$/, "")}/${normalizedRelative}`;
}

function clientConnectionIp(): string {
  if (process.env.DOCKER_IPYKERNEL_HOST) {
    return process.env.DOCKER_IPYKERNEL_HOST;
  }

  return "127.0.0.1";
}

function publishedPort(port: number): string {
  const bindHost = process.env.DOCKER_IPYKERNEL_BIND_HOST;
  if (!bindHost) {
    return `${port}:${port}`;
  }
  return `${bindHost}:${port}:${port}`;
}

function shouldUseLocalForwarder(): boolean {
  if (process.env.DOCKER_IPYKERNEL_DISABLE_FORWARDER === "1") {
    return false;
  }
  return Boolean(process.env.HOST_DIR);
}

async function startLocalForwarders(ports: number[]): Promise<net.Server[]> {
  const servers: net.Server[] = [];
  const listenHost =
    process.env.DOCKER_IPYKERNEL_FORWARD_LISTEN_HOST || "127.0.0.1";
  const targetHost =
    process.env.DOCKER_IPYKERNEL_FORWARD_TARGET || "host.docker.internal";

  for (const port of ports) {
    const server = net.createServer((clientSocket) => {
      const upstream = net.createConnection({
        host: targetHost,
        port,
      });

      clientSocket.on("error", () => {
        upstream.destroy();
      });
      upstream.on("error", () => {
        clientSocket.destroy();
      });

      clientSocket.pipe(upstream);
      upstream.pipe(clientSocket);
    });

    await new Promise<void>((resolve, reject) => {
      server.once("error", reject);
      server.listen(port, listenHost, () => {
        server.off("error", reject);
        resolve();
      });
    });

    servers.push(server);
  }

  return servers;
}

async function stopLocalForwarders(servers: net.Server[]): Promise<void> {
  await Promise.all(
    servers.map(
      (server) =>
        new Promise<void>((resolve) => {
          server.close(() => {
            resolve();
          });
        }),
    ),
  );
}

async function investigateImage(options: InvestOptions): Promise<void> {
  const specs = await listContainerKernelSpecs(
    options.image,
    options.pythonCommand,
  );
  const entries = Object.entries(specs.kernelspecs).sort(([left], [right]) =>
    left.localeCompare(right),
  );

  if (entries.length === 0) {
    console.log(`No kernelspecs found in ${options.image}`);
    return;
  }

  console.log(`Kernelspecs in ${options.image}:`);
  for (const [name, spec] of entries) {
    console.log(`- ${name}`);
    console.log(`  display: ${spec.spec.display_name}`);
    if (spec.spec.language) {
      console.log(`  language: ${spec.spec.language}`);
    }
  }
}

async function addKernelSpec(options: AddOptions): Promise<void> {
  assertKernelName(options.kernelName);

  const listedSpecs = await listContainerKernelSpecs(
    options.image,
    options.pythonCommand,
  );
  const containerKernel = listedSpecs.kernelspecs[options.containerKernelName];
  if (!containerKernel) {
    const available = Object.keys(listedSpecs.kernelspecs).sort();
    const suffix =
      available.length === 0
        ? " no kernelspecs were returned"
        : ` available kernels: ${available.join(", ")}`;
    throw new Error(
      `container kernelspec '${options.containerKernelName}' was not found in image '${options.image}';${suffix}`,
    );
  }

  const scriptDir = path.dirname(import.meta.filename);
  const repoRoot = path.resolve(scriptDir, "..");
  const kernelsRoot = await resolveLocalKernelsRoot();
  const kernelDir = path.join(kernelsRoot, options.kernelName);
  const kernelJsonPath = path.join(kernelDir, "kernel.json");
  const launcherPath = path.join(repoRoot, "scripts", "docker-ipykernel.ts");

  const kernelArgv = [
    "node",
    launcherPath,
    "run",
    "--image",
    options.image,
    "--kernel-argv-json",
    JSON.stringify([
      ...options.pythonCommand.split(" "),
      ...containerKernel.spec.argv.slice(1, -2),
    ]),
    "--kernel-env-json",
    JSON.stringify(containerKernel.spec.env ?? {}),
    "-f",
    "{connection_file}",
  ];

  const kernelSpec = {
    argv: kernelArgv,
    display_name: options.displayName,
    language: containerKernel.spec.language || "python",
    metadata: {
      ...(containerKernel.spec.metadata ?? {}),
      debugger: (containerKernel.spec.language || "python") === "python",
    },
    interrupt_mode: containerKernel.spec.interrupt_mode,
    kernel_protocol_version: "5.5",
  };

  await fs.mkdir(kernelDir, { recursive: true });
  await fs.writeFile(
    kernelJsonPath,
    JSON.stringify(kernelSpec, null, 2) + "\n",
    "utf8",
  );

  console.log(`Created kernelspec: ${path.relative(repoRoot, kernelJsonPath)}`);
  console.log(`Kernel name: ${options.kernelName}`);
  console.log(`Display name: ${options.displayName}`);
  console.log(`Container kernelspec: ${options.containerKernelName}`);
  console.log("Select this kernel from VS Code Jupyter kernel picker.");
}

function asJupyterPaths(value: unknown): JupyterPaths {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("jupyter --paths --json returned invalid JSON");
  }

  const data = (value as { data?: unknown }).data;
  if (!Array.isArray(data) || data.some((entry) => typeof entry !== "string")) {
    throw new Error(
      "jupyter --paths --json did not include a valid data path list",
    );
  }

  return { data };
}

async function resolveLocalKernelsRoot(): Promise<string> {
  const result = await runLocalJupyter(["--paths", "--json"]);
  if (result.code !== 0) {
    const msg = result.stderr.trim() || result.stdout.trim();
    throw new Error(`failed to query local jupyter paths: ${msg}`);
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(result.stdout) as unknown;
  } catch {
    throw new Error("failed to parse JSON from jupyter --paths --json");
  }

  const paths = asJupyterPaths(parsed);
  if (paths.data.length === 0) {
    throw new Error("jupyter --paths --json returned no data directories");
  }

  const dataDir = paths.data[0];
  if (!dataDir) {
    throw new Error(
      "jupyter --paths --json returned an empty primary data directory",
    );
  }

  return path.join(dataDir, "kernels");
}

async function listLocalKernelSpecs(_options: ListOptions): Promise<void> {
  const result = await runLocalJupyter(["kernelspec", "list", "--json"]);
  if (result.code !== 0) {
    const msg = result.stderr.trim() || result.stdout.trim();
    throw new Error(`failed to list local kernelspecs via jupyter: ${msg}`);
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(result.stdout) as unknown;
  } catch {
    throw new Error("failed to parse JSON from jupyter kernelspec list --json");
  }

  const specs = asContainerKernelSpecList(parsed);
  const entries = Object.entries(specs.kernelspecs).sort(([left], [right]) =>
    left.localeCompare(right),
  );

  if (entries.length === 0) {
    console.log("No local kernelspecs found");
    return;
  }

  console.log("Local kernelspecs:");
  for (const [name, spec] of entries) {
    console.log(`- ${name}`);
    console.log(`  display: ${spec.spec.display_name}`);
    if (spec.spec.language) {
      console.log(`  language: ${spec.spec.language}`);
    }
  }
}

async function runCommand(
  cmd: string,
  args: string[],
): Promise<{ stdout: string; stderr: string; code: number }> {
  return await new Promise((resolve, reject) => {
    console.log(`Running command: ${cmd} ${args.join(" ")}`);
    const child = spawn(cmd, args, {
      stdio: ["pipe", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => {
      stdout += String(chunk);
    });
    child.stderr.on("data", (chunk) => {
      stderr += String(chunk);
    });

    child.once("error", (error) => {
      reject(error);
    });

    child.once("close", (code) => {
      resolve({ stdout, stderr, code: code ?? 1 });
    });
  });
}

async function runLocalJupyter(
  args: string[],
): Promise<{ stdout: string; stderr: string; code: number }> {
  try {
    return await runCommand("jupyter", args);
  } catch (error: unknown) {
    const code =
      error && typeof error === "object" && "code" in error
        ? String((error as { code?: unknown }).code)
        : "";
    if (code === "ENOENT") {
      throw new Error(
        "local 'jupyter' command was not found on PATH; install jupyter-core or expose the intended jupyter executable on PATH",
      );
    }
    throw error;
  }
}

function createContainerName(image: string): string {
  const imagePart = image
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40);
  const suffix = randomUUID().slice(0, 8);
  return `docker-ipykernel-${imagePart || "image"}-${process.pid}-${suffix}`;
}

async function removeDockerContainer(containerName: string): Promise<void> {
  const result = await runCommand("docker", ["rm", "-f", containerName]);
  if (result.code === 0) {
    return;
  }

  const output = `${result.stderr}\n${result.stdout}`;
  if (/No such container/i.test(output)) {
    return;
  }

  throw new Error(
    `failed to remove container '${containerName}': ${output.trim()}`,
  );
}

async function listContainerKernelSpecs(
  image: string,
  pythonCommand: string,
): Promise<ContainerKernelSpecList> {
  const command = `${pythonCommand} -m jupyter kernelspec list --json 2> /dev/null`;
  const result = await runCommand("docker", [
    "run",
    "--rm",
    "--entrypoint",
    "/bin/sh",
    "-i",
    image,
    "-c",
    "--",
    command,
  ]);

  if (result.code !== 0) {
    const msg = result.stderr.trim() || result.stdout.trim();
    throw new Error(
      `failed to list kernelspecs in image '${image}' with python command '${pythonCommand}': ${msg}`,
    );
  }

  const text = result.stdout.trim();
  if (!text) {
    throw new Error(
      `image '${image}' returned no kernelspec JSON for python command '${pythonCommand}'`,
    );
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new Error(`failed to parse kernelspec JSON from image '${image}'`);
  }

  return asContainerKernelSpecList(parsed);
}

async function runKernel(options: RunOptions): Promise<void> {
  const scriptDir = path.dirname(import.meta.filename);
  const repoRoot = path.resolve(scriptDir, "..");
  const connectionFile = path.resolve(options.connectionFile);

  const connectionRaw = await fs.readFile(connectionFile, "utf8");
  const hostConnection = asConnectionInfo(JSON.parse(connectionRaw) as unknown);

  const notebookPath = detectNotebookPath();
  const notebookDir = notebookPath ? path.dirname(notebookPath) : process.cwd();
  const notebookDirResolved = path.resolve(notebookDir);

  const hostNotebookDir = toHostPath(notebookDirResolved, repoRoot);

  // Keep the client-side connection file reachable from devcontainer.
  const clientInfo: ConnectionInfo = {
    ...hostConnection,
    ip: clientConnectionIp(),
  };
  await fs.writeFile(connectionFile, JSON.stringify(clientInfo), "utf8");

  // Container side must bind on all interfaces for docker port publishing.
  const containerConnectionDir = path.join(repoRoot, ".tmp");
  await fs.mkdir(containerConnectionDir, { recursive: true });
  const containerConnectionHostPath = path.join(
    containerConnectionDir,
    path.basename(connectionFile),
  );

  const containerInfo: ConnectionInfo = {
    ...hostConnection,
    ip: "0.0.0.0",
  };
  await fs.writeFile(
    containerConnectionHostPath,
    JSON.stringify(containerInfo),
    "utf8",
  );

  const hostConnectionHostPath = toHostPath(
    containerConnectionHostPath,
    repoRoot,
  );
  const containerConnectionPath = `/tmp/docker-ipykernel/${path.basename(connectionFile)}`;
  const ports = [
    hostConnection.shell_port,
    hostConnection.iopub_port,
    hostConnection.stdin_port,
    hostConnection.control_port,
    hostConnection.hb_port,
  ];

  const uniquePorts = [...new Set(ports)];
  const useForwarder = shouldUseLocalForwarder();
  const forwarders = useForwarder
    ? await startLocalForwarders(uniquePorts)
    : [];
  const containerName = createContainerName(options.image);
  const dockerArgs: string[] = [
    "run",
    "--rm",
    "--name",
    containerName,
    "-v",
    `${hostNotebookDir}:/workdir`,
    "-w",
    "/workdir",
    "-v",
    `${hostConnectionHostPath}:${containerConnectionPath}:ro`,
  ];

  for (const port of uniquePorts) {
    dockerArgs.push("-p", publishedPort(port));
  }

  for (const [key, value] of Object.entries(options.kernelEnv)) {
    dockerArgs.push("-e", `${key}=${value}`);
  }

  dockerArgs.push(
    "--entrypoint",
    options.kernelArgv[0] || "python",
    "-i",
    options.image,
    ...options.kernelArgv.slice(1),
    "-f",
    containerConnectionPath,
  );

  console.error(`docker-ipykernel: notebook dir = ${notebookDirResolved}`);
  console.error(`docker-ipykernel: mounted host dir = ${hostNotebookDir}`);
  console.error(
    `docker-ipykernel: mounted connection file = ${containerConnectionHostPath}`,
  );
  console.error(`docker-ipykernel: client connection ip = ${clientInfo.ip}`);
  console.error(
    `docker-ipykernel: published ports = ${uniquePorts.map((port) => publishedPort(port)).join(", ")}`,
  );
  if (useForwarder) {
    console.error(
      `docker-ipykernel: local forwarder enabled (127.0.0.1 -> host.docker.internal) on ports ${uniquePorts.join(", ")}`,
    );
  }
  console.error(
    `docker-ipykernel: launch argv = ${JSON.stringify(dockerArgs)}`,
  );
  console.error(`docker-ipykernel: launching image = ${options.image}`);

  const child = spawn("docker", dockerArgs, {
    stdio: "inherit",
  });

  await new Promise<void>((resolve, reject) => {
    let cleanupPromise: Promise<void> | null = null;
    let settled = false;
    let terminationSignal: NodeJS.Signals | null = null;

    const cleanupRuntime = async (): Promise<void> => {
      if (!cleanupPromise) {
        cleanupPromise = Promise.allSettled([
          fs.rm(containerConnectionHostPath, { force: true }),
          stopLocalForwarders(forwarders),
          removeDockerContainer(containerName),
        ]).then(() => undefined);
      }

      await cleanupPromise;
    };

    const onSigint = (): void => {
      terminate("SIGINT");
    };
    const onSigterm = (): void => {
      terminate("SIGTERM");
    };

    const removeSignalHandlers = (): void => {
      process.off("SIGINT", onSigint);
      process.off("SIGTERM", onSigterm);
    };

    const finishWithSignal = (signal: NodeJS.Signals): void => {
      if (settled) {
        return;
      }

      settled = true;
      removeSignalHandlers();
      process.kill(process.pid, signal);
    };

    const finishWithCode = (code: number | null): void => {
      if (settled) {
        return;
      }

      settled = true;
      removeSignalHandlers();
      process.exitCode = code ?? 1;
      resolve();
    };

    const terminate = (signal: NodeJS.Signals): void => {
      if (terminationSignal) {
        return;
      }

      terminationSignal = signal;
      if (!child.killed) {
        child.kill(signal);
      }

      void cleanupRuntime().finally(() => {
        finishWithSignal(signal);
      });
    };

    process.on("SIGINT", onSigint);
    process.on("SIGTERM", onSigterm);

    child.once("error", (error) => {
      void cleanupRuntime().finally(() => {
        if (settled) {
          return;
        }

        settled = true;
        removeSignalHandlers();
        reject(error);
      });
    });

    child.once("exit", (code, signal) => {
      void cleanupRuntime().finally(() => {
        if (terminationSignal) {
          finishWithSignal(terminationSignal);
          return;
        }

        if (signal) {
          finishWithSignal(signal);
          return;
        }

        finishWithCode(code);
      });
    });
  });
}

async function main(): Promise<void> {
  const argv = process.argv.slice(2);
  const command = argv[0];

  if (!command || command === "-h" || command === "--help") {
    usage();
    return;
  }

  const subArgs = argv.slice(1);
  if (command === "add") {
    await addKernelSpec(parseAddArgs(subArgs));
    return;
  }

  if (command === "list") {
    await listLocalKernelSpecs(parseListArgs(subArgs));
    return;
  }

  if (command === "run") {
    await runKernel(parseRunArgs(subArgs));
    return;
  }

  if (command === "invest") {
    await investigateImage(parseInvestArgs(subArgs));
    return;
  }

  throw new Error(`unknown subcommand: ${command}`);
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Failed to process docker ipykernel command: ${message}`);
  process.exitCode = 1;
});
