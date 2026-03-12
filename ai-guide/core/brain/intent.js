function detectIntent(message) {
  const msg = message.toLowerCase();

  if (msg.includes("hello") || msg.includes("hi")) return "GREETING";
  if (
    msg.includes("what you do") ||
    msg.includes("who are you") ||
    msg.includes("help")
  )
    return "ABOUT_BOT";
  if (msg.includes("complaint")) return "COMPLAINT";
  if (msg.includes("delay")) return "DELAY";
  if (msg.includes("escalate")) return "ESCALATION";
  if (msg.includes("thank")) return "THANKS";

  return "UNKNOWN";
}

module.exports = detectIntent;
