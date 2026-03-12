import readline from "readline-sync";
import { askLocalAI } from "./localAI.js";

console.log("🤖 SwachConnect Advanced AI (Local) started");
console.log("You can ask me anything about the app or cleanliness.");
console.log("Type 'exit' to stop.\n");

while (true) {
  const userInput = readline.question("You: ");

  if (userInput.toLowerCase() === "exit") {
    console.log("AI: Goodbye 👋 Stay clean, stay responsible.");
    break;
  }

  try {
    const reply = await askLocalAI(userInput);
    console.log("AI:", reply);
  } catch (error) {
    console.error(error);
    console.log("AI: Sorry, I had trouble thinking. Please try again.");
  }
}
