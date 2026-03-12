class AIGuideStep {
  final String id;
  final String message;

  AIGuideStep({required this.id, required this.message});
}

class AIGuideState {
  int _currentIndex = 0;

  final List<AIGuideStep> steps = [
    AIGuideStep(
      id: "welcome",
      message: "Welcome to SwachConnect. I will guide you step by step.",
    ),
    AIGuideStep(
      id: "register",
      message:
          "Here you can register a complaint by uploading a photo. Location will be fetched automatically.",
    ),
    AIGuideStep(
      id: "anonymous",
      message:
          "You may submit the complaint with your name or anonymously.",
    ),
    AIGuideStep(
      id: "history",
      message:
          "Here you can track your submitted complaints and their progress.",
    ),
    AIGuideStep(
      id: "finish",
      message:
          "That’s all. SwachConnect is developed by Meven Regi, Benita Biju George, Aswathy Nair S, and Dhanush K Anil.",
    ),
  ];

  AIGuideStep get current => steps[_currentIndex];

  bool get hasNext => _currentIndex < steps.length - 1;

  void next() {
    if (hasNext) _currentIndex++;
  }

  void reset() {
    _currentIndex = 0;
  }
}
