import 'dart:async';
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_text.dart';
import 'config.dart';
import 'otp_page.dart';
import 'register_complaint_page.dart';
import 'complaint_history_page.dart';

/// 🔹 Global notifier to rebuild entire app when language changes
ValueNotifier<int> languageNotifier = ValueNotifier(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppText.loadLanguage();
  runApp(const SwachConnectApp());
}

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
            scaffoldBackgroundColor: const Color(0xFFF6F7FB),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

/* ================= SPLASH ================= */

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  String displayText = "SwachConnect";
  bool showTypewriter = true;

  final List<String> languages = [
    "സ്വച്‌കണക്റ്റ്",
    "स्वच्छकनेक्ट",
    "சுவச் கனெக்ட்",
    "స్వచ్ కనెక్ట్",
    "ಸ್ವಚ್ ಕನెక్ట್",
    "SwachConnect"
  ];

  @override
  void initState() {
    super.initState();
    startSplashFlow();
  }

  Future<void> startSplashFlow() async {
    // wait for typewriter to finish
    await Future.delayed(const Duration(milliseconds: 1700));

    setState(() => showTypewriter = false);

    // multilingual blink
    for (String lang in languages) {
      setState(() => displayText = lang);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    // final blink pause
    await Future.delayed(const Duration(milliseconds: 250));

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
      MaterialPageRoute(
        builder: (_) =>
        token == null || token.isEmpty
            ? const LoginPage()
            : const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: showTypewriter
            ? AnimatedTextKit(
          totalRepeatCount: 1,
          animatedTexts: [
            TypewriterAnimatedText(
              'SwachConnect',
              speed: const Duration(milliseconds: 120),
              textStyle: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        )
            : AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            displayText,
            key: ValueKey(displayText),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}

/* ================= LOGIN ================= */

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

  final backendBase = AppConfig.backendBase;

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
        Uri.parse("$backendBase/api/auth/login"),
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
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        _snack(AppText.t("invalidLogin"));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _snack(AppText.t("networkError"));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppText.t("login"))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: email,
                  decoration: InputDecoration(
                    labelText: AppText.t("email"),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppText.t("enterEmail");
                    }
                    if (!v.contains("@")) {
                      return AppText.t("invalidEmail");
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: password,
                  obscureText: hide,
                  decoration: InputDecoration(
                    labelText: AppText.t("password"),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hide ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => hide = !hide),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppText.t("enterPassword");
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    ),
                    child: Text(AppText.t("forgot")),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(AppText.t("login")),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: Text(
                    AppText.t("registerPrompt"),
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

/* ================= REGISTER ================= */

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

  bool hide1 = true;
  bool hide2 = true;
  bool loading = false;

  final backendBase = AppConfig.backendBase;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse("$backendBase/api/auth/register"),
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
          final msg = data["message"] ?? AppText.t("registrationFailed");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppText.t("registrationFailed"))),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.t("networkError"))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppText.t("register"))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(labelText: AppText.t("name")),
                  validator: (v) =>
                  v == null || v.isEmpty ? AppText.t("enterName") : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: email,
                  decoration: InputDecoration(labelText: AppText.t("email")),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppText.t("enterEmail");
                    }
                    if (!v.contains("@")) {
                      return AppText.t("invalidEmail");
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: password,
                  obscureText: hide1,
                  decoration: InputDecoration(
                    labelText: AppText.t("password"),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hide1 ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => hide1 = !hide1),
                    ),
                  ),
                  validator: (v) =>
                  v != null && v.length < 6
                      ? AppText.t("passwordMin")
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPassword,
                  obscureText: hide2,
                  decoration: InputDecoration(
                    labelText: AppText.t("confirmPassword"),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hide2 ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => hide2 = !hide2),
                    ),
                  ),
                  validator: (v) =>
                  v != password.text
                      ? AppText.t("passwordMismatch")
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : register,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(AppText.t("register").toUpperCase()),
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

/* ================= FORGOT PASSWORD ================= */

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = TextEditingController();
    final backendBase = AppConfig.backendBase;

    Future<void> sendOtp() async {
      await http.post(
        Uri.parse("$backendBase/api/auth/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.text.trim()}),
      );

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPPage(email: email.text.trim()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppText.t("forgotPassword"))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: InputDecoration(
                labelText: AppText.t("email"),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendOtp,
              child: Text(AppText.t("sendOtp")),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= HOME ================= */

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _controller = PageController();
  Timer? _timer;
  int index = 0;

  String name = "User";

  final slides = [
    "assets/slideshow/slide1.png",
    "assets/slideshow/slide2.png",
    "assets/slideshow/slide3.png",
  ];

  @override
  void initState() {
    super.initState();
    _loadName();

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      index = (index + 1) % slides.length;
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() =>
      name = prefs.getString(AppConfig.nameKey) ?? AppText.t("name"));
    }
  }

  /// logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(" ").first;
    final statusBar = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              /// SLIDESHOW
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: Stack(
                  fit: StackFit.expand,
                  children: [

                    /// IMAGE SLIDER
                    PageView.builder(
                      controller: _controller,
                      itemCount: slides.length,
                      itemBuilder: (_, i) =>
                          Image.asset(slides[i], fit: BoxFit.cover),
                    ),

                    /// DARK OVERLAY
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black87,
                            Colors.black45,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    /// HEADER
                    Positioned(
                      top: statusBar + 10,
                      left: 16,
                      right: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          /// LEFT SIDE
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                /// TITLE
                                const Text(
                                  "SwachConnect",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  "${AppText.t("welcome")}, $firstName 👋",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// RIGHT ICONS
                          Row(
                            children: [

                              /// LANGUAGE BUTTON (NEW CLEAN MENU)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.language,
                                    color: Colors.white,
                                  ),
                                  onSelected: (value) async {
                                    await AppText.setLanguage(value);
                                    languageNotifier.value++;

                                    if (mounted) {
                                      setState(() {});
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                        value: "en", child: Text("English")),
                                    PopupMenuItem(
                                        value: "ml", child: Text("Malayalam")),
                                    PopupMenuItem(
                                        value: "hi", child: Text("Hindi")),
                                    PopupMenuItem(
                                        value: "ta", child: Text("Tamil")),
                                    PopupMenuItem(
                                        value: "te", child: Text("Telugu")),
                                    PopupMenuItem(
                                        value: "kn", child: Text("Kannada")),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              /// PROFILE MENU
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.account_circle,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onSelected: (value) {
                                    if (value == "logout") {
                                      _logout();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: "logout",
                                      child: Text(AppText.t("logout")),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// HOME BUTTONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [

                    _homeCard(
                      AppText.t("registerComplaint"),
                      Icons.camera_alt,
                      Colors.green,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterComplaintPage(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _homeCard(
                      AppText.t("myComplaints"),
                      Icons.history,
                      Colors.blue,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ComplaintHistoryPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeCard(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [

            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}