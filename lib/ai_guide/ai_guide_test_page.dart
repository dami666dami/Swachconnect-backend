import 'package:flutter/material.dart';
import 'ai_guide_controller.dart';

class AIGuideTestPage extends StatefulWidget {
  const AIGuideTestPage({super.key});

  @override
  State<AIGuideTestPage> createState() => _AIGuideTestPageState();
}

class _AIGuideTestPageState extends State<AIGuideTestPage> {
  final guide = AIGuideController();

  @override
  void initState() {
    super.initState();
    guide.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Guide Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: guide.next,
          child: const Text("NEXT STEP"),
        ),
      ),
    );
  }
}
