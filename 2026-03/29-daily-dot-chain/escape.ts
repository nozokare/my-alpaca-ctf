const code = `process.execve("/usr/bin/sh")`;

// [.0-9A-z] 以外の文字を \xHH 形式でエスケープする
const escaped = code.replace(/[^.0-9A-Za-z]/g, (match) => {
  return `\\x${match.charCodeAt(0).toString(16).padStart(2, "0")}`;
});

console.log("Function`" + escaped + "```");
