function getReply(intent) {
  switch (intent) {
    case "GREETING":
      return "Hello 👋 I’m your SwachConnect AI assistant. I can help you with complaints, delays, escalation, and useful tips.";

    case "ABOUT_BOT":
      return "I assist users in understanding how the SwachConnect app works, guide them through complaints, escalation, and promote cleanliness awareness.";

    case "COMPLAINT":
      return "To register a complaint, upload a clear photo of the waste along with accurate GPS location. This helps authorities act quickly.";

    case "DELAY":
      return "I understand delays can be frustrating. Let’s check whether waiting or escalation is the best option for you.";

    case "ESCALATION":
      return "Escalation should be done only after the given deadline if the issue remains unresolved.";

    case "THANKS":
      return "You’re welcome 😊 I’m always here to help you.";

    default:
      return "I didn’t fully understand that. You can ask me about complaints, delays, escalation, or how this app works.";
  }
}

module.exports = getReply;
