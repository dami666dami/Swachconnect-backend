import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

// ─── Design Tokens ──────────────────────────────────────────────────────────
class _Colors {
  static const bg = Color(0xFF060910);
  static const surface = Color(0xFF0D1117);
  static const card = Color(0xFF161C2D);
  static const cardElevated = Color(0xFF1C2438);
  static const cardBorder = Color(0xFF1E2D4A);
  static const cardBorderHighlight = Color(0xFF2A3F6F);
  static const accent = Color(0xFF4F8EF7);
  static const accentLight = Color(0xFF6BA3FF);
  static const accentDark = Color(0xFF2563EB);
  static const accentGlow = Color(0x284F8EF7);
  static const accentGlowStrong = Color(0x404F8EF7);
  static const success = Color(0xFF0EA472);
  static const successGlow = Color(0x220EA472);
  static const warning = Color(0xFFF5A623);
  static const warningGlow = Color(0x22F5A623);
  static const danger = Color(0xFFE84040);
  static const dangerGlow = Color(0x28E84040);
  static const purple = Color(0xFF7C3AED);
  static const purpleGlow = Color(0x227C3AED);
  static const textPrimary = Color(0xFFECF0F7);
  static const textSecondary = Color(0xFF5A6A88);
  static const textTertiary = Color(0xFF8494B0);
  static const textMuted = Color(0xFF283347);
  static const divider = Color(0xFF151D2E);
  static const shimmer1 = Color(0xFF1A2235);
  static const shimmer2 = Color(0xFF1E2A40);

  static const headerGrad = LinearGradient(
    colors: [Color(0xFF060910), Color(0xFF0A1020)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const accentGrad = LinearGradient(
    colors: [Color(0xFF4F8EF7), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const dangerGrad = LinearGradient(
    colors: [Color(0xFFE84040), Color(0xFFB91C1C)],
  );

  static const successGrad = LinearGradient(
    colors: [Color(0xFF0EA472), Color(0xFF047857)],
  );
}

// ─── Shared Prefs Keys ───────────────────────────────────────────────────────
class _PrefKeys {
  static const role = 'user_role';
}

// ─── Status Badge ────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'resolved':
        color = _Colors.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'pending':
        color = _Colors.warning;
        icon = Icons.schedule_rounded;
        break;
      default:
        color = _Colors.accent;
        icon = Icons.fiber_new_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _Colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _Colors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                color: _Colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: _Colors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Tab Item ─────────────────────────────────────────────────────────────────
class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final int? badge;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _Colors.accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? _Colors.accent.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? _Colors.accent : _Colors.textSecondary, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: active ? _Colors.accent : _Colors.textSecondary,
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _Colors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Role Badge ───────────────────────────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  const _RoleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: _Colors.accentGrad,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: _Colors.accentGlowStrong, blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 11),
          SizedBox(width: 5),
          Text(
            'ADMIN MODE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Icon Button ─────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool badge;
  final Color? iconColor;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _Colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Colors.cardBorder, width: 1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: iconColor ?? _Colors.textSecondary, size: 18),
              if (badge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _Colors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Divider ─────────────────────────────────────────────────────────────────
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: _Colors.divider);
  }
}

// ─── Main AdminPage ───────────────────────────────────────────────────────────
class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  // State
  List complaints = [];
  List users = [];
  bool loadingComplaints = true;
  bool loadingUsers = false;
  String _searchQuery = '';
  String _filter = 'All';
  int _activeTab = 0; // 0 = Complaints, 1 = Users

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _headerGlowController;
  late Animation<double> _headerGlowAnim;

  final List<String> _filters = ['All', 'Pending', 'Resolved', 'New'];

  @override
  void initState() {
    super.initState();

    _checkAccess(); // 🔥 access control

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _headerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _headerGlowAnim = CurvedAnimation(
      parent: _headerGlowController,
      curve: Curves.easeInOut,
    );

    fetchComplaints();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerGlowController.dispose();
    super.dispose();
  }

  // ── API Calls ──────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey);
  }

  Future<void> fetchComplaints() async {
    setState(() => loadingComplaints = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse("${AppConfig.backendBase}/api/complaints/all"),
        headers: AppConfig.jsonHeaders(token: token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          complaints = data["complaints"] ?? data["data"] ?? data;
          loadingComplaints = false;
        });
        _fadeController.forward(from: 0);
      } else {
        throw Exception("Status ${res.statusCode}");
      }
    } catch (e) {
      setState(() => loadingComplaints = false);
      _showSnack('Failed to load complaints', isError: true);
    }
  }

  Future<void> _checkAccess() async {
    final prefs = await SharedPreferences.getInstance();

    final role = prefs.getString('user_role');
    final realRole = prefs.getString('real_role');
    if (realRole != 'admin') {
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );
      return;
    }
    if (role == null) {
      await prefs.setString('user_role', 'admin');
    }
  }

  Future<void> fetchUsers() async {
    setState(() => loadingUsers = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse("${AppConfig.backendBase}/api/users/all"),
        headers: AppConfig.jsonHeaders(token: token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          users = data["users"] ?? data;
          loadingUsers = false;
        });
      } else {
        throw Exception("Status ${res.statusCode}");
      }
    } catch (e) {
      setState(() => loadingUsers = false);
      _showSnack('Failed to load users', isError: true);
    }
  }

  Future<void> deleteComplaint(String id, String desc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(description: desc),
    );
    if (confirmed != true) return;
    try {
      final token = await _getToken();
      final res = await http.delete(
        Uri.parse("${AppConfig.backendBase}/api/complaints/$id"),
        headers: AppConfig.jsonHeaders(token: token),
      );
      if (res.statusCode == 200) {
        _showSnack('Complaint deleted successfully');
      } else {
        _showSnack('Delete failed', isError: true);
      }
    } catch (e) {
      _showSnack('Network error', isError: true);
    }
    fetchComplaints();
  }

  Future<void> markResolved(String id) async {
    try {
      final token = await _getToken();
      await http.put(
        Uri.parse("${AppConfig.backendBase}/api/complaints/resolve/$id"),
        headers: AppConfig.jsonHeaders(token: token),
      );
      _showSnack('Marked as resolved');
      fetchComplaints();
    } catch (e) {
      _showSnack('Failed to update status', isError: true);
    }
  }

  Future<void> addRemark(String id) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => _RemarkDialog(
        controller: controller,
        onSubmit: () async {
          try {
            final token = await _getToken();
            await http.put(
              Uri.parse("${AppConfig.backendBase}/api/complaints/add-remark/$id"),
              headers: AppConfig.jsonHeaders(token: token),
              body: jsonEncode({"remark": controller.text}),
            );
            Navigator.pop(context);
            _showSnack('Remark added successfully');
            fetchComplaints();
          } catch (e) {
            _showSnack('Failed to add remark', isError: true);
          }
        },
      ),
    );
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final token = await _getToken();
      final res = await http.put(
        Uri.parse("${AppConfig.backendBase}/api/users/$userId/role"),
        headers: AppConfig.jsonHeaders(token: token),
        body: jsonEncode({"role": newRole}),
      );
      if (res.statusCode == 200) {
        _showSnack(newRole == 'admin' ? 'User promoted to Admin' : 'Admin role removed');
        fetchUsers();
      } else {
        _showSnack('Role update failed', isError: true);
      }
    } catch (e) {
      _showSnack('Network error', isError: true);
    }
  }

  // ── Auth / Role ────────────────────────────────────────────────────────────

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutDialog(),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
    await prefs.remove('user_role');
    await prefs.remove('real_role');
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

    Future<void> _switchToUserMode() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _SwitchRoleDialog(toAdmin: false),
      );

      if (confirmed != true) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', 'user');
      await Future.delayed(Duration(milliseconds: 200));
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
            (route) => false,
      );
    }


  Future<void> _switchToAdminMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _SwitchRoleDialog(toAdmin: true),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final realRole = prefs.getString('real_role');

    if (realRole == 'admin') {
      await prefs.setString('user_role', 'admin');
      await Future.delayed(Duration(milliseconds: 200));
    } else {
      _showSnack("Access denied", isError: true);
      return;
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
          (route) => false,
    );
  }
  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 17,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? _Colors.danger : _Colors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List get _filteredComplaints {
    return complaints.where((c) {
      final desc = (c['description'] ?? '').toLowerCase();
      final status = (c['status'] ?? '').toLowerCase();
      final user = (c['userId']?['name'] ?? '').toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          desc.contains(_searchQuery.toLowerCase()) ||
          user.contains(_searchQuery.toLowerCase());
      final matchFilter = _filter == 'All' || status == _filter.toLowerCase();
      return matchSearch && matchFilter;
    }).toList();
  }

  int _countByStatus(String s) =>
      complaints.where((c) => (c['status'] ?? '').toLowerCase() == s.toLowerCase()).length;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const _SectionDivider(),
            if (!loadingComplaints) _buildStats(),
            _buildTabs(),
            const _SectionDivider(),
            if (_activeTab == 0) _buildSearchAndFilter(),
            Expanded(
              child: _activeTab == 0
                  ? _buildComplaintsTab()
                  : _buildUsersTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerGlowAnim,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            gradient: _Colors.headerGrad,
          ),
          child: Row(
            children: [
              // Logo
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: _Colors.accentGrad,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: _Colors.accent.withOpacity(0.30 + _headerGlowAnim.value * 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 13),
              // Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text(
                        'Admin Console',
                        style: TextStyle(
                          color: _Colors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const _RoleBadge(),
                ],
              ),
              const Spacer(),
              // Refresh
              _IconBtn(
                icon: Icons.refresh_rounded,
                onTap: _activeTab == 0 ? fetchComplaints : fetchUsers,
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 7),
              // Switch to User
              FutureBuilder<String?>(
                future: SharedPreferences.getInstance()
                    .then((prefs) => prefs.getString('real_role')),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  final realRole = snapshot.data;

                  // ❌ Hide button for normal users
                  if (realRole != 'admin') {
                    return const SizedBox();
                  }

                  // ✅ Show only for admin
                  return _IconBtn(
                    icon: Icons.swap_horiz_rounded,
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final currentRole = prefs.getString('user_role');

                      if (currentRole == 'admin') {
                        _switchToUserMode();
                      } else {
                        _switchToAdminMode();
                      }
                    },
                    tooltip: 'Switch Mode',
                    iconColor: _Colors.warning,
                  );
                },
              ),
              const SizedBox(width: 7),
              // Logout
              _IconBtn(
                icon: Icons.logout_rounded,
                onTap: _handleLogout,
                tooltip: 'Logout',
                iconColor: _Colors.danger,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  Widget _buildStats() {
    final pending = _countByStatus('pending');
    final resolved = _countByStatus('resolved');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _StatCard(
            label: 'Total',
            value: '${complaints.length}',
            color: _Colors.accent,
            icon: Icons.inbox_rounded,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Pending',
            value: '$pending',
            color: _Colors.warning,
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Resolved',
            value: '$resolved',
            color: _Colors.success,
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Users',
            value: users.isEmpty ? '—' : '${users.length}',
            color: _Colors.purple,
            icon: Icons.group_rounded,
          ),
        ],
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────
  Widget _buildTabs() {
    final pendingCount = _countByStatus('pending') + _countByStatus('new');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          _TabItem(
            label: 'Complaints',
            icon: Icons.chat_bubble_outline_rounded,
            active: _activeTab == 0,
            badge: pendingCount > 0 ? pendingCount : null,
            onTap: () => setState(() => _activeTab = 0),
          ),
          const SizedBox(width: 8),
          _TabItem(
            label: 'Users',
            icon: Icons.group_outlined,
            active: _activeTab == 1,
            onTap: () {
              setState(() => _activeTab = 1);
              if (users.isEmpty) fetchUsers();
            },
          ),
        ],
      ),
    );
  }

  // ── Search + Filter ───────────────────────────────────────────────────────
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: _Colors.card,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _Colors.cardBorder, width: 1),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: _Colors.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search complaints or users...',
                hintStyle: const TextStyle(color: _Colors.textSecondary, fontSize: 13.5),
                prefixIcon: const Icon(Icons.search_rounded, color: _Colors.textSecondary, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _Colors.textSecondary, size: 16),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 33,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final active = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: active ? _Colors.accent : _Colors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? _Colors.accent : _Colors.cardBorder,
                        width: 1,
                      ),
                      boxShadow: active
                          ? [BoxShadow(color: _Colors.accentGlow, blurRadius: 10)]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      f,
                      style: TextStyle(
                        color: active ? Colors.white : _Colors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Complaints Tab ────────────────────────────────────────────────────────
  Widget _buildComplaintsTab() {
    if (loadingComplaints) return _buildLoader('Loading complaints...');
    final filtered = _filteredComplaints;
    if (filtered.isEmpty) return _buildEmpty('No complaints found', 'Try adjusting your search or filters');
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _ComplaintCard(
          complaint: filtered[i],
          index: i,
          onDelete: () => deleteComplaint(filtered[i]['_id'] ?? '', filtered[i]['description'] ?? ''),
          onRemark: () => addRemark(filtered[i]['_id'] ?? ''),
          onResolve: filtered[i]['status']?.toLowerCase() != 'resolved'
              ? () => markResolved(filtered[i]['_id'] ?? '')
              : null,
        ),
      ),
    );
  }

  // ── Users Tab ─────────────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    if (loadingUsers) return _buildLoader('Loading users...');
    if (users.isEmpty) return _buildEmpty('No users found', 'Pull to refresh or check the API');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      itemCount: users.length,
      itemBuilder: (_, i) => _UserCard(
        user: users[i],
        index: i,
        onPromote: () => updateUserRole(users[i]['_id'] ?? '', 'admin'),
        onDemote: () => updateUserRole(users[i]['_id'] ?? '', 'user'),
      ),
    );
  }

  // ── Generic States ────────────────────────────────────────────────────────
  Widget _buildLoader(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _Colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _Colors.cardBorder),
            ),
            child: const CircularProgressIndicator(color: _Colors.accent, strokeWidth: 2.5),
          ),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: _Colors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _Colors.card,
              shape: BoxShape.circle,
              border: Border.all(color: _Colors.cardBorder),
            ),
            child: const Icon(Icons.inbox_rounded, color: _Colors.textMuted, size: 38),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: _Colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: _Colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Complaint Card ───────────────────────────────────────────────────────────
class _ComplaintCard extends StatefulWidget {
  final Map complaint;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onRemark;
  final VoidCallback? onResolve;

  const _ComplaintCard({
    required this.complaint,
    required this.index,
    required this.onDelete,
    required this.onRemark,
    this.onResolve,
  });

  @override
  State<_ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<_ComplaintCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 50),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final hasRemark = (c['remark'] ?? '').toString().isNotEmpty;
    final id = (c['_id'] ?? '').toString();
    final shortId = id.length > 8 ? '...${id.substring(id.length - 8)}' : id;
    final dateStr = _formatDate(c['createdAt']);
    final isResolved = (c['status'] ?? '').toLowerCase() == 'resolved';

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _Colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isResolved
                    ? _Colors.success.withOpacity(0.18)
                    : _Colors.cardBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                children: [
                  // Top gradient line
                  Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: isResolved
                          ? _Colors.successGrad
                          : _Colors.accentGrad,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _Colors.accent.withOpacity(0.75),
                                    const Color(0xFF6366F1).withOpacity(0.75),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (c['userId']?['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['userId']?['name'] ?? 'Unknown User',
                                    style: const TextStyle(
                                      color: _Colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c['userId']?['email'] ?? '',
                                    style: const TextStyle(
                                      color: _Colors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(c['status'] ?? 'new'),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Meta row: ID + timestamp
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _Colors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _Colors.cardBorder),
                              ),
                              child: Text(
                                'ID: $shortId',
                                style: const TextStyle(
                                  color: _Colors.textSecondary,
                                  fontSize: 9.5,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (dateStr.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.access_time_rounded, size: 10, color: _Colors.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: _Colors.textSecondary,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 12),
                        Container(height: 1, color: _Colors.divider),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          c['description'] ?? 'No description provided.',
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _Colors.textTertiary,
                            fontSize: 13,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        // Remark
                        if (hasRemark) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: _Colors.accent.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _Colors.accent.withOpacity(0.15), width: 1),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.comment_rounded, color: _Colors.accent, size: 13),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    c['remark'],
                                    style: const TextStyle(
                                      color: _Colors.textSecondary,
                                      fontSize: 11.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                label: 'Add Remark',
                                icon: Icons.edit_note_rounded,
                                color: _Colors.accent,
                                onTap: widget.onRemark,
                              ),
                            ),
                            if (widget.onResolve != null) ...[
                              const SizedBox(width: 8),
                              _ActionButton(
                                label: 'Resolve',
                                icon: Icons.check_circle_outline_rounded,
                                color: _Colors.success,
                                onTap: widget.onResolve!,
                                iconOnly: true,
                              ),
                            ],
                            const SizedBox(width: 8),
                            _ActionButton(
                              label: 'Delete',
                              icon: Icons.delete_outline_rounded,
                              color: _Colors.danger,
                              onTap: widget.onDelete,
                              iconOnly: true,
                            ),
                          ],
                        ),
                      ],
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

// ─── User Card ────────────────────────────────────────────────────────────────
class _UserCard extends StatefulWidget {
  final Map user;
  final int index;
  final VoidCallback onPromote;
  final VoidCallback onDemote;

  const _UserCard({
    required this.user,
    required this.index,
    required this.onPromote,
    required this.onDemote,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 50),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _avatarColor(String name) {
    final colors = [_Colors.accent, _Colors.purple, _Colors.success, _Colors.warning];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final name = u['name'] ?? 'Unknown';
    final email = u['email'] ?? '';
    final role = (u['role'] ?? 'user').toString().toLowerCase();
    final isAdmin = role == 'admin';
    final color = _avatarColor(name);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _Colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isAdmin ? _Colors.accent.withOpacity(0.22) : _Colors.cardBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: _Colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: const TextStyle(color: _Colors.textSecondary, fontSize: 11.5),
                    ),
                    const SizedBox(height: 6),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? _Colors.accent.withOpacity(0.10)
                            : _Colors.textMuted.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isAdmin
                              ? _Colors.accent.withOpacity(0.25)
                              : _Colors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          color: isAdmin ? _Colors.accent : _Colors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Action button
              GestureDetector(
                onTap: isAdmin ? widget.onDemote : widget.onPromote,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? _Colors.danger.withOpacity(0.10)
                        : _Colors.success.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAdmin
                          ? _Colors.danger.withOpacity(0.25)
                          : _Colors.success.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdmin ? Icons.remove_moderator_rounded : Icons.admin_panel_settings_rounded,
                        color: isAdmin ? _Colors.danger : _Colors.success,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isAdmin ? 'Remove Admin' : 'Promote',
                        style: TextStyle(
                          color: isAdmin ? _Colors.danger : _Colors.success,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool iconOnly;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: EdgeInsets.symmetric(horizontal: iconOnly ? 12 : 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withOpacity(0.22), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: iconOnly ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(icon, color: color, size: 15),
            if (!iconOnly) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Logout Dialog ────────────────────────────────────────────────────────────
class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _Colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _Colors.danger.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _Colors.danger.withOpacity(0.2), width: 1),
              ),
              child: const Icon(Icons.logout_rounded, color: _Colors.danger, size: 28),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sign Out?',
              style: TextStyle(color: _Colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will be logged out and redirected to the login screen.',
              style: TextStyle(color: _Colors.textSecondary, fontSize: 12.5, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _DialogButton(label: 'Cancel', onTap: () => Navigator.pop(context, false), primary: false)),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'Sign Out',
                    onTap: () => Navigator.pop(context, true),
                    primary: true,
                    gradient: _Colors.dangerGrad,
                    glowColor: _Colors.dangerGlow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Switch Role Dialog ───────────────────────────────────────────────────────
class _SwitchRoleDialog extends StatelessWidget {
  final bool toAdmin;
  const _SwitchRoleDialog({required this.toAdmin});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _Colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _Colors.warning.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _Colors.warning.withOpacity(0.2)),
              ),
              child: const Icon(Icons.swap_horiz_rounded, color: _Colors.warning, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              toAdmin ? 'Switch to Admin?' : 'Switch to User Mode?',
              style: const TextStyle(color: _Colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              toAdmin
                  ? 'You will be taken to the Admin Console.'
                  : 'You will be taken to the normal user app. Admin controls will be hidden.',
              style: const TextStyle(color: _Colors.textSecondary, fontSize: 12.5, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _DialogButton(label: 'Cancel', onTap: () => Navigator.pop(context, false), primary: false)),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'Switch',
                    onTap: () => Navigator.pop(context, true),
                    primary: true,
                    gradient: const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFD97706)]),
                    glowColor: _Colors.warningGlow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Delete Dialog ────────────────────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  final String description;
  const _DeleteDialog({required this.description});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _Colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _Colors.danger.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _Colors.danger.withOpacity(0.2)),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: _Colors.danger, size: 28),
            ),
            const SizedBox(height: 18),
            const Text(
              'Delete Complaint?',
              style: TextStyle(color: _Colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: _Colors.textSecondary, fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _DialogButton(label: 'Cancel', onTap: () => Navigator.pop(context, false), primary: false)),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'Delete',
                    onTap: () => Navigator.pop(context, true),
                    primary: true,
                    gradient: _Colors.dangerGrad,
                    glowColor: _Colors.dangerGlow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Remark Dialog ────────────────────────────────────────────────────────────
class _RemarkDialog extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _RemarkDialog({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _Colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _Colors.accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: _Colors.accent, size: 18),
                ),
                const SizedBox(width: 13),
                const Text(
                  'Add Remark',
                  style: TextStyle(color: _Colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: _Colors.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _Colors.cardBorder),
              ),
              child: TextField(
                controller: controller,
                maxLines: 4,
                style: const TextStyle(color: _Colors.textPrimary, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Write your remark here...',
                  hintStyle: TextStyle(color: _Colors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(15),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _DialogButton(label: 'Cancel', onTap: () => Navigator.pop(context), primary: false)),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'Submit',
                    onTap: onSubmit,
                    primary: true,
                    gradient: _Colors.accentGrad,
                    glowColor: _Colors.accentGlow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Dialog Button ─────────────────────────────────────────────────────
class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final Gradient? gradient;
  final Color? glowColor;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.primary,
    this.gradient,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: primary ? gradient : null,
          color: primary ? null : _Colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: primary ? null : Border.all(color: _Colors.cardBorder),
          boxShadow: primary && glowColor != null
              ? [BoxShadow(color: glowColor!, blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.white : _Colors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}