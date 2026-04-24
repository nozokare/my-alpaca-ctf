const url = process.env.URL || "http://localhost:3000";

const res_create = await fetch(`${url}`, {
  method: "POST",
  body: `[&doc {command: create, content: "", isHidden: true}, *doc]`,
});

const sid = res_create.headers.get("set-cookie")?.match(/sid=([^;]+)/)?.[1];
const id = (await res_create.json()).results[0].id;

const res_get = await fetch(`${url}`, {
  method: "POST",
  headers: {
    Cookie: `sid=${sid}`,
  },
  body: `[{command: get, id: ${id}}]`,
});

console.log((await res_get.json()).results[0].content);
