import readline from "node:readline/promises";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

let input = "";
while (input !== "exit") {
  input = await rl.question("Enter input: ");
  try {
    const p1 = JSON.parse(input);
    console.log(p1);
    const p2 = JSON.parse(p1);
    console.log(p2);
    const p3 = JSON.parse(p2);
    console.log(p3);
    const p4 = JSON.parse(p3);
    console.log(p4);
    const ans = JSON.parse(p4);
    console.log(ans);

    if (ans === "42") {
      console.log("Correct!");
    } else {
      console.log("Incorrect!");
    }
  } catch (error) {
    console.error("Error parsing input:", error);
  }
}
