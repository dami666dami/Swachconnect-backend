import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with TickerProviderStateMixin {
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool loading = false;
  bool hide1 = true;
  bool hide2 = true;

  // Password strength
  double _strength = 0;
  String _strengthLabel = '';
  Color _strengthColor = Colors.transparent;

  static const String backendBase = "http://192.168.1.6:4000";

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _successCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _successAnim;

  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _pulseCtrl =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _successAnim =
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);

    _fadeCtrl.forward();
    _slideCtrl.forward();

    _passwordCtrl.addListener(_updateStrength);
    _passwordFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  /* ── STRENGTH ── */

  void _updateStrength() {
    final p = _passwordCtrl.text;
    double s = 0;
    if (p.length >= 6) s += 0.25;
    if (p.length >= 10) s += 0.15;
    if (p.contains(RegExp(r'[A-Z]'))) s += 0.2;
    if (p.contains(RegExp(r'[0-9]'))) s += 0.2;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) s += 0.2;

    String label;
    Color color;
    if (s == 0) {
      label = '';
      color = Colors.transparent;
    } else if (s <= 0.25) {
      label = 'Weak';
      color = const Color(0xFFEF5350);
    } else if (s <= 0.5) {
      label = 'Fair';
      color = const Color(0xFFFFB300);
    } else if (s <= 0.75) {
      label = 'Good';
      color = const Color(0xFF66BB6A);
    } else {
      label = 'Strong';
      color = const Color(0xFF43A047);
    }

    setState(() {
      _strength = s.clamp(0.0, 1.0);
      _strengthLabel = label;
      _strengthColor = color;
    });
  }

  /* ── RESET ── */

  Future<void> resetPassword() async {
    final newPassword = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (newPassword.length < 6) {
      _toast("Minimum 6 characters required");
      return;
    }
    if (newPassword != confirmPassword) {
      _toast("Passwords do not match");
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() => loading = true);
    HapticFeedback.lightImpact();

    try {
      final res = await http.post(
        Uri.parse("$backendBase/api/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email, "newPassword": newPassword}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        HapticFeedback.heavyImpact();
        setState(() => _showSuccess = true);
        _successCtrl.forward();
        await Future.delayed(const Duration(milliseconds: 1400));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        _toast(res.body);
      }
    } catch (_) {
      _toast("Server error. Please try again.");
    }

    if (mounted) setState(() => loading = false);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: const Color(0xFF1C1C2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  /* ── BUILD ── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      body: Stack(
        children: [
          _backgroundDecor(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    _topBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _headerSection(),
                            const SizedBox(height: 40),
                            _passwordField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              label: "New Password",
                              hide: hide1,
                              toggle: () => setState(() => hide1 = !hide1),
                            ),
                            const SizedBox(height: 10),
                            _strengthBar(),
                            const SizedBox(height: 16),
                            _passwordField(
                              controller: _confirmPasswordCtrl,
                              focusNode: _confirmFocus,
                              label: "Confirm Password",
                              hide: hide2,
                              toggle: () => setState(() => hide2 = !hide2),
                              isConfirm: true,
                            ),
                            const SizedBox(height: 12),
                            _matchIndicator(),
                            const SizedBox(height: 36),
                            _submitButton(),
                            const SizedBox(height: 28),
                            _requirementsCard(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showSuccess) _successOverlay(),
        ],
      ),
    );
  }

  /* ── BACKGROUND ── */

  Widget _backgroundDecor() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF4CAF50).withOpacity(0.16),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF2E7D32).withOpacity(0.13),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  /* ── TOP BAR ── */

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A3E)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /* ── HEADER ── */

  Widget _headerSection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.35),
                    blurRadius: 26,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: Colors.white, size: 42),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "New Password",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Create a strong password to\nkeep your account safe",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8888AA),
            fontSize: 14.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /* ── PASSWORD FIELD ── */

  Widget _passwordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool hide,
    required VoidCallback toggle,
    bool isConfirm = false,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasValue = controller.text.isNotEmpty;

    // match check for confirm field
    final isMatch = isConfirm &&
        controller.text.isNotEmpty &&
        _passwordCtrl.text.isNotEmpty &&
        controller.text == _passwordCtrl.text;

    final borderColor = isConfirm && controller.text.isNotEmpty
        ? (isMatch ? const Color(0xFF388E3C) : const Color(0xFFEF5350))
        : isFocused
        ? const Color(0xFF66BB6A)
        : hasValue
        ? const Color(0xFF2E5030)
        : const Color(0xFF2A2A3E);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF161625),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isFocused ? 2 : 1.5,
        ),
        boxShadow: isFocused
            ? [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.18),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: hide,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isFocused ? const Color(0xFF66BB6A) : const Color(0xFF555570),
            fontSize: 14,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF66BB6A),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            isConfirm ? Icons.lock_outline_rounded : Icons.key_rounded,
            color: isFocused ? const Color(0xFF66BB6A) : const Color(0xFF555570),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF555570),
              size: 20,
            ),
            onPressed: toggle,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  /* ── STRENGTH BAR ── */

  Widget _strengthBar() {
    if (_passwordCtrl.text.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  child: LinearProgressIndicator(
                    value: _strength,
                    backgroundColor: const Color(0xFF1C1C2E),
                    valueColor: AlwaysStoppedAnimation(_strengthColor),
                    minHeight: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _strengthLabel,
                key: ValueKey(_strengthLabel),
                style: TextStyle(
                  color: _strengthColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /* ── MATCH INDICATOR ── */

  Widget _matchIndicator() {
    final confirm = _confirmPasswordCtrl.text;
    if (confirm.isEmpty) return const SizedBox.shrink();

    final matches = confirm == _passwordCtrl.text;
    return Row(
      children: [
        Icon(
          matches ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 14,
          color: matches ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
        ),
        const SizedBox(width: 6),
        Text(
          matches ? "Passwords match" : "Passwords do not match",
          style: TextStyle(
            fontSize: 12.5,
            color: matches ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /* ── SUBMIT BUTTON ── */

  Widget _submitButton() {
    final canSubmit = _passwordCtrl.text.length >= 6 &&
        _passwordCtrl.text == _confirmPasswordCtrl.text;

    return GestureDetector(
      onTap: loading ? null : resetPassword,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: canSubmit
              ? const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: canSubmit ? null : const Color(0xFF1C1C2E),
          border: canSubmit ? null : Border.all(color: const Color(0xFF2A2A3E)),
          boxShadow: canSubmit
              ? [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.4),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ]
              : [],
        ),
        child: loading
            ? const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Reset Password",
              style: TextStyle(
                color: canSubmit
                    ? Colors.white
                    : const Color(0xFF555570),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            if (canSubmit) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  /* ── REQUIREMENTS CARD ── */

  Widget _requirementsCard() {
    final p = _passwordCtrl.text;
    final checks = [
      (_req("At least 6 characters", p.length >= 6)),
      (_req("One uppercase letter", p.contains(RegExp(r'[A-Z]')))),
      (_req("One number", p.contains(RegExp(r'[0-9]')))),
      (_req("One special character",
          p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')))),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131320),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Password Requirements",
            style: TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...checks,
        ],
      ),
    );
  }

  Widget _req(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met
                  ? const Color(0xFF1A2E1A)
                  : const Color(0xFF1C1C2E),
              border: Border.all(
                color: met
                    ? const Color(0xFF388E3C)
                    : const Color(0xFF2A2A3E),
              ),
            ),
            child: met
                ? const Icon(Icons.check_rounded,
                size: 11, color: Color(0xFF66BB6A))
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: met ? const Color(0xFF81C784) : const Color(0xFF555570),
              fontSize: 13,
              fontWeight: met ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /* ── SUCCESS OVERLAY ── */

  Widget _successOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: ScaleTransition(
          scale: _successAnim,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1A0E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2E5030)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Password Reset!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Redirecting you to login...",
                  style: TextStyle(color: Color(0xFF8888AA), fontSize: 13.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}