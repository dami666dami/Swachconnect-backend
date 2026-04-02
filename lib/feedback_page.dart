import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class FeedbackPage extends StatefulWidget {
final String complaintId;

const FeedbackPage({super.key, required this.complaintId});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with TickerProviderStateMixin {
  int rating = 0;
  int hoveredStar = 0;
  bool isSubmitting = false;
  final TextEditingController feedbackController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final List<AnimationController> _starControllers = [];
  final List<Animation<double>> _starAnimations = [];

  // Color palette
  static const Color _bg = Color(0xFF0D0F14);
  static const Color _surface = Color(0xFF161921);
  static const Color _card = Color(0xFF1E2230);
  static const Color _accent = Color(0xFFE8A857);
  static const Color _accentGlow = Color(0x40E8A857);
  static const Color _gold = Color(0xFFF5C842);
  static const Color _textPrimary = Color(0xFFF0EDE8);
  static const Color _textSecondary = Color(0xFF8A8F9E);
  static const Color _border = Color(0xFF2A2F3F);
  static const Color _inputBg = Color(0xFF13151C);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    for (int i = 0; i < 5; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      _starControllers.add(ctrl);
      _starAnimations.add(
        Tween<double>(begin: 1.0, end: 1.35).animate(
          CurvedAnimation(parent: ctrl, curve: Curves.elasticOut),
        ),
      );
    }

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    feedbackController.dispose();
    for (final c in _starControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onStarTap(int index) {
    setState(() => rating = index);
    for (int i = 0; i < index; i++) {
      Future.delayed(Duration(milliseconds: i * 60), () {
        if (mounted) {
          _starControllers[i].forward(from: 0);
        }
      });
    }
  }

  String get _ratingLabel {
    switch (rating) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Poor';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap to rate';
    }
  }

  Color get _ratingColor {
    switch (rating) {
      case 1:
        return const Color(0xFFE05C5C);
      case 2:
        return const Color(0xFFE07A3A);
      case 3:
        return const Color(0xFFD4B84A);
      case 4:
        return const Color(0xFF7DC87A);
      case 5:
        return const Color(0xFF5BC8A0);
      default:
        return _textSecondary;
    }
  }

  Future<void> _submitFeedback() async {
    if (rating == 0) {
      _showSnack('Please select a rating first', isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.put(
        Uri.parse("${AppConfig.backendBase}/api/complaints/feedback/${widget.complaintId}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "rating": rating,
          "feedback": feedbackController.text.trim(),
        }),
      );

      if (res.statusCode == 200) {
        _showSnack('Thank you! Your feedback matters 🙏', isError: false);

        setState(() {
          rating = 0;
          feedbackController.clear();
        });

        Navigator.pop(context);

      } else {
        final data = jsonDecode(res.body);
        _showSnack(data["message"] ?? "Failed", isError: true);
      }

    } catch (e) {
      _showSnack("Network error", isError: true);
    }

    setState(() => isSubmitting = false);
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isError
            ? const Color(0xFF3A1A1A)
            : const Color(0xFF1A3A2A),
        elevation: 0,
        content: Row(
          children: [
            Icon(
              isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: isError
                  ? const Color(0xFFE05C5C)
                  : const Color(0xFF5BC8A0),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: _textPrimary,
                  fontFamily: 'serif',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _textPrimary, size: 16),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _accentGlow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withOpacity(0.4)),
            ),
            child: const Text(
              'BETA',
              style: TextStyle(
                color: _accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -80,
            left: -60,
            child: _ambientBlob(200, const Color(0x18E8A857)),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: _ambientBlob(240, const Color(0x10A857E8)),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildRatingCard(),
                      const SizedBox(height: 20),
                      _buildFeedbackCard(),
                      const SizedBox(height: 28),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                      _buildPrivacyNote(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ambientBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: const SizedBox(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_accent, Color(0x00E8A857)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Share Your',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Experience',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Your feedback helps us craft a better experience for everyone.',
          style: TextStyle(
            color: _textSecondary.withOpacity(0.8),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          // Icon ring
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: rating > 0 ? 1.0 : _pulseAnimation.value,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surface,
                  border: Border.all(
                    color: rating > 0
                        ? _ratingColor.withOpacity(0.5)
                        : _border,
                    width: 2,
                  ),
                  boxShadow: rating > 0
                      ? [
                    BoxShadow(
                      color: _ratingColor.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    rating == 0
                        ? '✦'
                        : ['😞', '😕', '😐', '😊', '🤩'][rating - 1],
                    style: TextStyle(
                      fontSize: rating == 0 ? 22 : 30,
                      color: rating == 0 ? _textSecondary : null,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'HOW WAS YOUR EXPERIENCE?',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              final isActive = starIndex <= rating;
              return GestureDetector(
                onTap: () => _onStarTap(starIndex),
                child: AnimatedBuilder(
                  animation: _starAnimations[i],
                  builder: (_, __) => Transform.scale(
                    scale: isActive ? _starAnimations[i].value : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: isActive
                                ? [_gold, _accent]
                                : [_border, _border],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Icon(
                            isActive ? Icons.star_rounded : Icons.star_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _ratingLabel,
              key: ValueKey(rating),
              style: TextStyle(
                color: _ratingColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentGlow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: _accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tell us more',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Text(
                'Optional',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: feedbackController,
            maxLines: 5,
            maxLength: 300,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14.5,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'What made your experience great or what could be improved...',
              hintStyle: TextStyle(
                color: _textSecondary.withOpacity(0.5),
                fontSize: 13.5,
                height: 1.5,
              ),
              filled: true,
              fillColor: _inputBg,
              counterStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _accent.withOpacity(0.6), width: 1.5),
              ),
            ),
            cursorColor: _accent,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSubmitting
              ? [_surface, _surface]
              : [_accent, const Color(0xFFC8782A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSubmitting
            ? []
            : [
          BoxShadow(
            color: _accent.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSubmitting ? null : _submitFeedback,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white10,
          child: Center(
            child: isSubmitting
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(_accent),
              ),
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded, color: Color(0xFF1A0F00), size: 18),
                SizedBox(width: 10),
                Text(
                  'Submit Feedback',
                  style: TextStyle(
                    color: Color(0xFF1A0F00),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded,
            size: 13, color: _textSecondary.withOpacity(0.5)),
        const SizedBox(width: 6),
        Text(
          'Your response is anonymous and encrypted.',
          style: TextStyle(
            color: _textSecondary.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}