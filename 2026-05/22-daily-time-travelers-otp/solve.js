import crypto from "node:crypto";

const timeStep = 30;
const digits = 6;
const setupCode = "MQJZZVVPER3OXQ432ZS2LHPAEPHWWKAA";
const secret = decodeBase32(setupCode);

//const time = new Date("6109-06-14T21:06:30Z").getTime();
const time = Date.now() + 128849018790000;
console.log(getCurrentTOTP(secret, time));

function getCurrentTOTP(key, now) {
  const counter = Math.floor(now / 1000 / timeStep);
  const value = hotp(key, counter);
  return value.toString().padStart(digits, "0");
}

function decodeBase32(str) {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  const bits = [...str]
    .map((char) => alphabet.indexOf(char).toString(2).padStart(5, "0"))
    .join("");

  const bytes = [];
  for (let index = 0; index < bits.length; index += 8) {
    const chunk = bits.slice(index, index + 8);
    if (chunk.length === 8) {
      bytes.push(Number.parseInt(chunk, 2));
    }
  }

  return Buffer.from(bytes);
}

// HOTP(K, C) = Truncate(HMAC-SHA-1(K, C)) as defined in RFC 4226
export function hotp(key, counter) {
  const buf = Buffer.alloc(8);
  buf.writeUInt32BE((counter & 0xffff_ffff_0000_0000) >>> 32, 0);
  buf.writeUInt32BE(counter & 0x0000_0000_ffff_ffff, 4);
  return truncate(hmac_sha_1(key, buf));
}

// HMAC-SHA-1 defined in RFC 2104
export function hmac_sha_1(key, buf) {
  const hmac = crypto.createHmac("sha1", key);
  return hmac.update(buf).digest();
}

// Truncate function defined in RFC 4226
// `hash` is a 20-byte HMAC-SHA-1 hash
export function truncate(hash) {
  // get the offset (0 <= offset <= 15) from the last byte
  const offset = (hash[19] || 0) & 0x0f;

  // get 31-bit integer starting at the offset
  const value = hash.readUint32BE(offset) & 0x7fffffff;

  return value % 10 ** digits;
}
