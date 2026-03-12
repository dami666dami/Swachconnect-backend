import 'package:swachconnect/ai_guide/ai_guide_state.dart';
import 'package:swachconnect/ai_guide/ai_voice.dart';

class AIGuideController {
  final AIGuideState state = AIGuideState();
  final AIVoice voice = AIVoice();

  void start() {
    voice.speak(state.current.message);
  }

  void next() {
    state.next();
    voice.speak(state.current.message);
  }

  void reset() {
    state.reset();
  }
}
