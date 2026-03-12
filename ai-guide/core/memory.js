const conversationMemory = [];

export function addToMemory(role, content) {
  conversationMemory.push({ role, content });

  if (conversationMemory.length > 10) {
    conversationMemory.shift();
  }
}

export function getMemoryContext() {
  return conversationMemory
    .map(msg => `${msg.role}: ${msg.content}`)
    .join("\n");
}
