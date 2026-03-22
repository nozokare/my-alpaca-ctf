import { createReadStream } from "node:fs";
import { join } from "node:path";
import { createInterface } from "node:readline";

const filepath = join(import.meta.dirname, "handout", "flag.hex");

let N = 0;

const rl = createInterface({
  input: createReadStream(filepath),
  crlfDelay: Infinity,
});

let LEN = 0;
let bitSum = new Int32Array(0);

for await (const raw of rl) {
  const line = raw.trim();
  if (line.length === 0) continue;
  N++;

  const bytes = Buffer.from(line, "hex");

  if (LEN === 0) {
    LEN = bytes.length;
    bitSum = new Int32Array(LEN * 8);
  }

  for (let i = 0; i < LEN; i++) {
    const cypher = bytes[i]!;
    for (let j = 0; j < 8; j++) {
      bitSum[i * 8 + j]! += ~(cypher >> j) & 1;
    }
  }
}

const bits = bitSum.map((x) => (x > N / 2 ? 1 : 0));

const bytes = new Uint8Array(LEN);
for (let i = 0; i < LEN; i++) {
  for (let j = 0; j < 8; j++) {
    bytes[i]! |= bits[i * 8 + j]! << j;
  }
}

console.log(Buffer.from(bytes).toString());
