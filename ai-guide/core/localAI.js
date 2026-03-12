import { addToMemory, getMemoryContext } from "./memory.js";

export async function askLocalAI(userMessage) {
  addToMemory("User", userMessage);

  const memoryContext = getMemoryContext();

  const response = await fetch("http://localhost:11434/api/generate", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "mistral",
      prompt: `
You are SwachConnect AI Assistant.

About the application:
- SwachConnect is a smart waste management and complaint tracking application
- Developed by Meven Regi, Benita Biju George, Aswathy Nair S, and Dhanush K Anil
- Users can report waste using images and GPS location
- Complaints can be tracked, escalated, and monitored
- Email notifications are sent for complaint updates and escalations

Conversation so far:
${memoryContext}

Your responsibilities:
- Use conversation context to answer follow-up questions
- Guide users on how to use the SwachConnect app
- Explain complaint registration (photo + GPS)
- Explain delays, escalation, tracking, and notifications
- Give cleanliness and civic responsibility tips
- If the user asks about the app, developers, credits, or project details,
  clearly mention that SwachConnect is developed by
  Meven Regi, Benita Biju George, Aswathy Nair S, and Dhanush K Anil
- Answer naturally, politely, and clearly
- Do NOT give legal or medical advice

Current user question:
${userMessage}

Answer:
`,
      stream: false
    })
  });

  const data = await response.json();
  const aiReply = data.response;


  addToMemory("AI", aiReply);

  return aiReply;
}
