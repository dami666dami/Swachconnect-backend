function getTip(intent) {
  switch (intent) {
    case "COMPLAINT":
      return "💡 Tip: Clear images and correct location reduce resolution time.";

    case "DELAY":
      return "💡 Tip: If the deadline has not passed yet, waiting may resolve the issue faster.";

    case "ESCALATION":
      return "💡 Tip: Escalate only once after the deadline to avoid slowing down processing.";

    case "ABOUT_BOT":
      return "💡 Tip: You can talk to me freely like a human. I’ll guide you step by step.";

    default:
      return null;
  }
}

module.exports = getTip;
