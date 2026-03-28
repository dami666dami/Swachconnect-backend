import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_text.dart';
import 'config.dart';
import 'otp_page.dart';
import 'register_complaint_page.dart';
import 'complaint_history_page.dart';

/// Global notifier to rebuild entire app when language changes
ValueNotifier<int> languageNotifier = ValueNotifier(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await AppText.loadLanguage();
  runApp(const SwachConnectApp());
}

// ── Design System ──────────────────────────────────────────────────────────

class AppColors {
  // Earthy, rich greens — premium civic feel
  static const forest       = Color(0xFF1A3C2A);   // deep forest anchor
  static const pine         = Color(0xFF2D5A3D);   // primary brand
  static const moss         = Color(0xFF3E7A53);   // interactive elements
  static const sage         = Color(0xFF6BAB7E);   // accent / highlights
  static const mist         = Color(0xFFB8D9C2);   // soft border
  static const dew          = Color(0xFFE8F4EC);   // lightest surface tint

  // Warm neutrals — gives a premium editorial feel
  static const ink          = Color(0xFF0F1F15);   // text on white
  static const charcoal     = Color(0xFF2C3E30);   // headings
  static const slate        = Color(0xFF5A7262);   // body text
  static const ash          = Color(0xFF94A89C);   // muted / hints
  static const cloud        = Color(0xFFF4F7F5);   // page background
  static const paper        = Color(0xFFFFFFFF);   // cards

  // Gold accent — civic prestige
  static const gold         = Color(0xFFD4A843);
  static const goldLight    = Color(0xFFF5E4B0);

  // Status
  static const errorRed     = Color(0xFFD63031);

  // Gradients
  static const primaryGrad  = LinearGradient(
    colors: [forest, pine],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const heroGrad     = LinearGradient(
    colors: [Color(0xE8112210), Color(0x991A3C2A), Color(0x2A2D5A3D), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.35, 0.65, 1.0],
  );
  static const cardGrad     = LinearGradient(
    colors: [pine, moss],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const tealGrad     = LinearGradient(
    colors: [Color(0xFF1B5E45), Color(0xFF26876A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTypography {
  // Display — Playfair-feel weight contrast
  static const hero = TextStyle(
    fontSize: 38, fontWeight: FontWeight.w900,
    color: AppColors.charcoal, letterSpacing: -1.2,
    height: 1.1,
  );
  static const display = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: AppColors.charcoal, letterSpacing: -0.8,
    height: 1.2,
  );
  static const headline = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.charcoal, letterSpacing: -0.4,
  );
  static const title = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.charcoal, letterSpacing: -0.2,
  );
  static const body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.slate, height: 1.6,
  );
  static const caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.ash, letterSpacing: 1.4,
  );
  static const label = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.slate, letterSpacing: 0.1,
  );
}

// ── SwachConnect Custom Logo Widget ────────────────────────────────────────

class SwachConnectLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool lightText;

  const SwachConnectLogo({
    super.key,
    this.size = 44,
    this.showText = true,
    this.lightText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoMark(size: size),
        if (showText) ...[
          SizedBox(width: size * 0.22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Swach",
                style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w900,
                  color: lightText ? Colors.white : AppColors.forest,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
              Text(
                "Connect",
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w400,
                  color: lightText ? Colors.white.withValues(alpha: 0.75) : AppColors.sage,
                  letterSpacing: 1.2,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // --- Hexagonal container (rotated 30°) ---
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.forest, AppColors.moss],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final px = cx + (w * 0.48) * math.cos(angle);
      final py = cy + (h * 0.48) * math.sin(angle);
      if (i == 0) hexPath.moveTo(px, py);
      else hexPath.lineTo(px, py);
    }
    hexPath.close();
    canvas.drawPath(hexPath, bgPaint);

    // --- Inner leaf / water-drop accent (gold) ---
    final goldPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;

    final goldPath = Path();
    goldPath.moveTo(cx, cy - h * 0.28);
    goldPath.cubicTo(
      cx + w * 0.22, cy - h * 0.10,
      cx + w * 0.22, cy + h * 0.10,
      cx, cy + h * 0.28,
    );
    goldPath.cubicTo(
      cx - w * 0.22, cy + h * 0.10,
      cx - w * 0.22, cy - h * 0.10,
      cx, cy - h * 0.28,
    );
    canvas.drawPath(goldPath, goldPaint);

    // --- Recycling / connectivity arcs (white) ---
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Three circular arcs representing connection + cleanliness
    final arcR = w * 0.26;
    // Top arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy - h * 0.06), radius: arcR),
      -math.pi * 1.1, math.pi * 0.9, false, arcPaint,
    );
    // Bottom-left arc
    final blCenter = Offset(cx - w * 0.20, cy + h * 0.10);
    canvas.drawArc(
      Rect.fromCircle(center: blCenter, radius: arcR),
      math.pi * 0.55, math.pi * 0.9, false, arcPaint,
    );
    // Bottom-right arc
    final brCenter = Offset(cx + w * 0.20, cy + h * 0.10);
    canvas.drawArc(
      Rect.fromCircle(center: brCenter, radius: arcR),
      -math.pi * 0.15, math.pi * 0.9, false, arcPaint,
    );

    // --- Center dot (white) ---
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.06,
      Paint()..color = Colors.white,
    );

    // --- Gold ring border on hex ---
    final borderPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.5)
      ..strokeWidth = w * 0.025
      ..style = PaintingStyle.stroke;
    canvas.drawPath(hexPath, borderPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── App ─────────────────────────────────────────────────────────────────────

class SwachConnectApp extends StatelessWidget {
  const SwachConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: languageNotifier,
      builder: (context, value, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SwachConnect',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.cloud,
            fontFamily: 'Nunito', // Premium rounded sans
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.pine,
              primary: AppColors.pine,
              secondary: AppColors.sage,
              surface: AppColors.paper,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.paper,
              elevation: 0,
              scrolledUnderElevation: 1,
              surfaceTintColor: AppColors.paper,
              titleTextStyle: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700,
                color: AppColors.charcoal, letterSpacing: -0.3,
                fontFamily: 'Nunito',
              ),
              iconTheme: IconThemeData(color: AppColors.charcoal),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pine,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  letterSpacing: 0.4, fontFamily: 'Nunito',
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.cloud,
              labelStyle: AppTypography.label,
              floatingLabelStyle: const TextStyle(
                color: AppColors.pine, fontWeight: FontWeight.w700, fontSize: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.mist, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.mist, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.pine, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

/* ═══════════════════════════ SPLASH ═══════════════════════════ */

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _navigated = false;

  late AnimationController _fadeCtrl;
  late AnimationController _scaleCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _pulseAnim;

  String displayText = "SwachConnect";
  bool showTypewriter = true;

  final List<String> languages = [
    "സ്വച്‌കണക്റ്റ്",
    "स्वच्छकनेक्ट",
    "சுவச் கனெக்ட்",
    "స్వచ్ కనెక్ట్",
    "ಸ್ವಚ್ ಕನೆ‌ಕ್ಟ್",
    "SwachConnect",
  ];

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl.forward();
    _scaleCtrl.forward();
    startSplashFlow();
  }

  Future<void> startSplashFlow() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    setState(() => showTypewriter = false);
    for (final lang in languages) {
      setState(() => displayText = lang);
      await Future.delayed(const Duration(milliseconds: 380));
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (!_navigated) {
      _navigated = true;
      await _checkLogin();
    }
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConfig.tokenKey);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
        token == null || token.isEmpty ? const LoginPage() : const HomePage(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          // Background decorative circles
          Positioned(
            right: -size.width * 0.25,
            top: -size.width * 0.25,
            child: Container(
              width: size.width * 0.75,
              height: size.width * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.dew,
              ),
            ),
          ),
          Positioned(
            left: -size.width * 0.30,
            bottom: size.height * 0.10,
            child: Container(
              width: size.width * 0.70,
              height: size.width * 0.70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.dew.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Gold dot accent
          Positioned(
            right: size.width * 0.15,
            bottom: size.height * 0.28,
            child: Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold,
              ),
            ),
          ),
          Positioned(
            left: size.width * 0.10,
            top: size.height * 0.20,
            child: Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sage.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Main content
          FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo mark
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      ),
                      child: const SwachConnectLogo(size: 80, showText: false),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Brand name
                  showTypewriter
                      ? AnimatedTextKit(
                    totalRepeatCount: 1,
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'SwachConnect',
                        speed: const Duration(milliseconds: 100),
                        textStyle: AppTypography.hero.copyWith(
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  )
                      : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim, child: child,
                    ),
                    child: Text(
                      displayText,
                      key: ValueKey(displayText),
                      style: AppTypography.hero.copyWith(color: AppColors.forest),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tagline with gold underline
                  Column(
                    children: [
                      Text(
                        "Clean cities, connected communities",
                        style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.ash),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 40, height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom badge
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.dew,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.mist),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.sage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "CIVIC TECH FOR INDIA",
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ═══════════════════════════ SHARED AUTH WIDGETS ═══════════════════════════ */

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _AuthHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SwachConnectLogo(size: 38),
        const SizedBox(height: 36),
        // Thin accent rule
        Row(
          children: [
            Container(width: 3, height: 28, color: AppColors.pine,
                margin: const EdgeInsets.only(right: 12)),
            Expanded(
              child: Text(title, style: AppTypography.display),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTypography.body),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Polished snack bar helper
void _showSnack(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white, size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: isError ? AppColors.errorRed : AppColors.pine,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      elevation: 0,
    ),
  );
}

/// Premium button with loading state and gradient
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final IconData? icon;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: loading
                ? const LinearGradient(colors: [AppColors.mist, AppColors.mist])
                : AppColors.cardGrad,
            borderRadius: BorderRadius.circular(16),
            boxShadow: loading ? null : [
              BoxShadow(
                color: AppColors.pine.withValues(alpha: 0.30),
                blurRadius: 16, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: loading ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: loading
                  ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.pine, strokeWidth: 2.5,
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w700, letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ═══════════════════════════ LOGIN ═══════════════════════════ */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool hide = true;
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.backendBase}/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.text.trim(),
          "password": password.text.trim(),
        }),
      );
      if (!mounted) return;
      setState(() => loading = false);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.tokenKey, body["token"]);
        await prefs.setString(AppConfig.nameKey, body["user"]["name"]);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomePage(),
            transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          ),
        );
      } else {
        _showSnack(context, AppText.t("invalidLogin"), isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnack(context, AppText.t("networkError"), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthHeader(
                  title: AppText.t("login"),
                  subtitle: "Welcome back — sign in to continue.",
                ),

                // Email field
                _FieldLabel(label: AppText.t("email")),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "you@example.com",
                    hintStyle: AppTypography.body.copyWith(color: AppColors.ash),
                    prefixIcon: _FieldIcon(icon: Icons.mail_outline_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppText.t("enterEmail");
                    if (!v.contains("@")) return AppText.t("invalidEmail");
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password field
                _FieldLabel(label: AppText.t("password")),
                TextFormField(
                  controller: password,
                  obscureText: hide,
                  decoration: InputDecoration(
                    hintText: "••••••••",
                    hintStyle: AppTypography.body.copyWith(color: AppColors.ash),
                    prefixIcon: _FieldIcon(icon: Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.ash, size: 20,
                      ),
                      onPressed: () => setState(() => hide = !hide),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? AppText.t("enterPassword") : null,
                ),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.pine,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                    ),
                    child: Text(
                      AppText.t("forgot"),
                      style: AppTypography.label.copyWith(
                        color: AppColors.pine, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                _PrimaryButton(
                  label: AppText.t("login"),
                  loading: loading,
                  onTap: login,
                ),

                const SizedBox(height: 28),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.mist)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("or", style: AppTypography.body.copyWith(fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: AppColors.mist)),
                  ],
                ),

                const SizedBox(height: 24),

                // Register CTA
                _AuthFooterCta(
                  question: "Don't have an account?",
                  action: AppText.t("register"),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ═══════════════════════════ REGISTER ═══════════════════════════ */

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool hide1 = true, hide2 = true, loading = false;

  @override
  void dispose() {
    name.dispose(); email.dispose();
    password.dispose(); confirmPassword.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.backendBase}/api/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name.text.trim(),
          "email": email.text.trim(),
          "password": password.text.trim(),
        }),
      );
      if (!mounted) return;
      setState(() => loading = false);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.tokenKey, body["token"]);
        await prefs.setString(AppConfig.nameKey, body["user"]["name"]);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
              (_) => false,
        );
      } else {
        try {
          final data = jsonDecode(res.body);
          _showSnack(context, data["message"] ?? AppText.t("registrationFailed"), isError: true);
        } catch (_) {
          _showSnack(context, AppText.t("registrationFailed"), isError: true);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnack(context, AppText.t("networkError"), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        leading: _BackButton(),
        backgroundColor: AppColors.cloud,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AuthHeader(
                title: AppText.t("register"),
                subtitle: "Join SwachConnect and make a difference.",
              ),

              _FieldLabel(label: AppText.t("name")),
              TextFormField(
                controller: name,
                decoration: InputDecoration(
                  hintText: "Your full name",
                  hintStyle: AppTypography.body.copyWith(color: AppColors.ash),
                  prefixIcon: _FieldIcon(icon: Icons.person_outline_rounded),
                ),
                validator: (v) => v == null || v.isEmpty ? AppText.t("enterName") : null,
              ),

              const SizedBox(height: 20),

              _FieldLabel(label: AppText.t("email")),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "you@example.com",
                  hintStyle: AppTypography.body.copyWith(color: AppColors.ash),
                  prefixIcon: _FieldIcon(icon: Icons.mail_outline_rounded),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return AppText.t("enterEmail");
                  if (!v.contains("@")) return AppText.t("invalidEmail");
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _FieldLabel(label: AppText.t("password")),
              TextFormField(
                controller: password,
                obscureText: hide1,
                decoration: InputDecoration(
                  hintText: "Min. 6 characters",
                  hintStyle: AppTypography.body.copyWith(color: AppColors.ash),
                  prefixIcon: _FieldIcon(icon: Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hide1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.ash, size: 20,
                    ),
                    onPressed: () => setState(() => hide1 = !hide1),
                  ),
                ),
                validator: (v) => v != null && v.length < 6 ? AppText.t("passwordMin") : null,
              ),

              const SizedBox(height: 20),

              _FieldLabel(label: AppText.t("confirmPassword")),
              TextFormField(
                controller: confirmPassword,
                obscureText: hide2,
                decoration: InputDecoration(
                  hintText: "Re-enter password",
                  hintStyle: AppTypography.body.copyWith(color: AppColors.ash),
                  prefixIcon: _FieldIcon(icon: Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hide2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.ash, size: 20,
                    ),
                    onPressed: () => setState(() => hide2 = !hide2),
                  ),
                ),
                validator: (v) => v != password.text ? AppText.t("passwordMismatch") : null,
              ),

              const SizedBox(height: 32),

              _PrimaryButton(
                label: AppText.t("register"),
                loading: loading,
                onTap: register,
              ),

              const SizedBox(height: 28),

              _AuthFooterCta(
                question: "Already have an account?",
                action: AppText.t("login"),
                onTap: () => Navigator.pop(context),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/* ═══════════════════════════ FORGOT PASSWORD ═══════════════════════════ */

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();

    Future<void> sendOtp() async {
      await http.post(
        Uri.parse("${AppConfig.backendBase}/api/auth/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailCtrl.text.trim()}),
      );
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OTPPage(email: emailCtrl.text.trim())),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cloud,
      appBar: AppBar(
        leading: _BackButton(),
        backgroundColor: AppColors.cloud,
        title: Text(AppText.t("forgotPassword")),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dew,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mist),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.sage, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "We'll send a one-time password to your registered email address.",
                      style: AppTypography.body.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _FieldLabel(label: AppText.t("email")),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "you@example.com",
                hintStyle: AppTypography.body.copyWith(color: AppColors.ash),
                prefixIcon: _FieldIcon(icon: Icons.mail_outline_rounded),
              ),
            ),

            const SizedBox(height: 28),

            _PrimaryButton(
              label: AppText.t("sendOtp"),
              loading: false,
              onTap: sendOtp,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

/* ═══════════════════════════ HOME ═══════════════════════════ */

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  Timer? _timer;
  int _slideIndex = 0;
  String name = "User";
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  final slides = [
    "assets/slideshow/slide1.png",
    "assets/slideshow/slide2.png",
    "assets/slideshow/slide3.png",
  ];

  // Stat counters
  final stats = [
    {"label": "Reports Filed", "count": "12.4K", "icon": Icons.assignment_turned_in_outlined},
    {"label": "Cities Active", "count": "38", "icon": Icons.location_city_outlined},
    {"label": "Issues Resolved", "count": "9.1K", "icon": Icons.check_circle_outline_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadName();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _slideIndex = (_slideIndex + 1) % slides.length;
      _pageCtrl.animateToPage(
        _slideIndex,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
      setState(() {});
    });
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => name = prefs.getString(AppConfig.nameKey) ?? "User");
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
          (_) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(" ").first;
    final topPad = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.cloud,
      body: FadeTransition(
        opacity: _entryAnim,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── HERO ──────────────────────────────────────────
              SizedBox(
                height: screenH * 0.50,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Slides
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: slides.length,
                      onPageChanged: (i) => setState(() => _slideIndex = i),
                      itemBuilder: (_, i) =>
                          Image.asset(slides[i], fit: BoxFit.cover),
                    ),

                    // Gradient overlay
                    Container(
                      decoration: const BoxDecoration(gradient: AppColors.heroGrad),
                    ),

                    // Bottom vignette into background
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, AppColors.cloud],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // Header
                    Positioned(
                      top: topPad + 14,
                      left: 20, right: 20,
                      child: Row(
                        children: [
                          Expanded(
                            child: SwachConnectLogo(
                              size: 36, showText: true, lightText: true,
                            ),
                          ),
                          // Language
                          _GlassIconBtn(
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.language_rounded, color: Colors.white, size: 19),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              onSelected: (v) async {
                                await AppText.setLanguage(v);
                                languageNotifier.value++;
                                if (mounted) setState(() {});
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: "en", child: Text("English")),
                                PopupMenuItem(value: "ml", child: Text("Malayalam")),
                                PopupMenuItem(value: "hi", child: Text("Hindi")),
                                PopupMenuItem(value: "ta", child: Text("Tamil")),
                                PopupMenuItem(value: "te", child: Text("Telugu")),
                                PopupMenuItem(value: "kn", child: Text("Kannada")),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Profile
                          _GlassIconBtn(
                            child: PopupMenuButton<String>(
                              icon: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                                child: Text(
                                  firstName.isNotEmpty ? firstName[0].toUpperCase() : "U",
                                  style: const TextStyle(
                                    color: Colors.white, fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              onSelected: (v) { if (v == "logout") _logout(); },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  enabled: false,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: AppTypography.title.copyWith(fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text("Citizen Member", style: AppTypography.caption),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: "logout",
                                  child: Row(
                                    children: [
                                      const Icon(Icons.logout_rounded, size: 16, color: AppColors.errorRed),
                                      const SizedBox(width: 10),
                                      Text(AppText.t("logout"),
                                          style: const TextStyle(color: AppColors.errorRed)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom: greeting + dots
                    Positioned(
                      bottom: 24, left: 20, right: 20,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${AppText.t("welcome")}, $firstName 👋",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22, fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Let's keep our city clean today.",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.80),
                                    fontSize: 13, fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Slide dots
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(slides.length, (i) =>
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  width: 5,
                                  height: i == _slideIndex ? 18 : 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: i == _slideIndex ? 1.0 : 0.4),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── STATS STRIP ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pine.withValues(alpha: 0.08),
                        blurRadius: 20, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(stats.length * 2 - 1, (i) {
                      if (i.isOdd) {
                        return Container(
                          width: 1, height: 36,
                          color: AppColors.mist,
                        );
                      }
                      final stat = stats[i ~/ 2];
                      return Expanded(
                        child: Column(
                          children: [
                            Icon(stat["icon"] as IconData, color: AppColors.sage, size: 18),
                            const SizedBox(height: 4),
                            Text(
                              stat["count"] as String,
                              style: AppTypography.title.copyWith(color: AppColors.forest),
                            ),
                            Text(
                              stat["label"] as String,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10, letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // ── SECTION HEADING ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
                child: Row(
                  children: [
                    Container(width: 3, height: 18, color: AppColors.gold,
                        margin: const EdgeInsets.only(right: 10)),
                    Text("QUICK ACTIONS", style: AppTypography.caption),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Text("What would you like to do?", style: AppTypography.headline),
              ),

              // ── ACTION CARDS ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _PremiumActionCard(
                      title: AppText.t("registerComplaint"),
                      subtitle: "Capture, report, and track civic issues with photo evidence",
                      icon: Icons.camera_alt_rounded,
                      gradient: AppColors.cardGrad,
                      badgeLabel: "REPORT NOW",
                      badgeColor: AppColors.gold,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterComplaintPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PremiumActionCard(
                      title: AppText.t("myComplaints"),
                      subtitle: "View, track, and follow up on all your past submissions",
                      icon: Icons.history_rounded,
                      gradient: AppColors.tealGrad,
                      badgeLabel: "MY HISTORY",
                      badgeColor: AppColors.sage,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ComplaintHistoryPage()),
                      ),
                    ),
                  ],
                ),
              ),

              // ── BOTTOM INFO CARD ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: _InfoBanner(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glassmorphic icon button
class _GlassIconBtn extends StatelessWidget {
  final Widget child;
  const _GlassIconBtn({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Premium full-bleed action card with gradient, badge and arrow
class _PremiumActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final String badgeLabel;
  final Color badgeColor;
  final VoidCallback onTap;

  const _PremiumActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.badgeLabel,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: 0.25),
                blurRadius: 24, offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon circle
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25), width: 1,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),

                    const Spacer(),

                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.40), width: 1,
                        ),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeColor == AppColors.gold
                              ? AppColors.goldLight
                              : Colors.white.withValues(alpha: 0.85),
                          fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13, height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                // Bottom CTA row
                Row(
                  children: [
                    Text(
                      "Get started",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13, fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Info bottom banner
class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mist),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star_rounded, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your voice matters",
                  style: AppTypography.title.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  "Every complaint filed brings us closer to cleaner cities.",
                  style: AppTypography.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable auth widgets ──────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption,
      ),
    );
  }
}

class _FieldIcon extends StatelessWidget {
  final IconData icon;
  const _FieldIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: AppColors.ash, size: 20);
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.dew,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.mist),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.charcoal),
      ),
    );
  }
}

class _AuthFooterCta extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;
  const _AuthFooterCta({required this.question, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: "$question  ",
          style: AppTypography.body.copyWith(fontSize: 14),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  action,
                  style: AppTypography.label.copyWith(
                    color: AppColors.pine,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.mist,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}