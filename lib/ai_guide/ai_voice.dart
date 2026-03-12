import 'package:flutter_tts/flutter_tts.dart';

class AIVoice {
  final FlutterTts _tts = FlutterTts();

  AIVoice() {
    _tts.setLanguage("en-IN");
    _tts.setSpeechRate(0.45);
    _tts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
