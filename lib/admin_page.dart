import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

// ─── Design Tokens ──────────────────────────────────────────────────────────
class _Colors {
  static const bg = Color(0xFF0A0D14);
  static const surface = Color(0xFF111827);
  static const card = Color(0xFF1A2235);
  static const cardBorder = Color(0xFF263354);
  static const accent = Color(0xFF3B82F6);
  static const accentGlow = Color(0x333B82F6);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const dangerGlow = Color(0x33EF4444);
  static const textPrimary = Color(0xFFE2E8F0);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF334155);
  static const divider = Color(0xFF1E293B);
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
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

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _Colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _Colors.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: _Colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: _Colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main Page ───────────────────────────────────────────────────────────────
class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  List complaints = [];
  bool loading = true;
  String _searchQuery = '';
  String _filter = 'All';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _filters = ['All', 'Pending', 'Resolved', 'New'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    fetchComplaints();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchComplaints() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);

      final res = await http.get(
        Uri.parse("${AppConfig.backendBase}/api/complaints/all"),
        headers: AppConfig.jsonHeaders(token: token),
      );

      final data = jsonDecode(res.body);
      setState(() {
        complaints = data["complaints"] ?? [];
        loading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() => loading = false);
      _showSnack('Failed to load complaints', isError: true);
    }
  }

  Future<void> deleteComplaint(String id, String desc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(description: desc),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConfig.tokenKey);

    await http.delete(
      Uri.parse("${AppConfig.backendBase}/api/complaints/$id"),
      headers: AppConfig.jsonHeaders(token: token),
    );

    _showSnack('Complaint deleted successfully');
    fetchComplaints();
  }

  Future<void> addRemark(String id) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => _RemarkDialog(
        controller: controller,
        onSubmit: () async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConfig.tokenKey);

          await http.put(
            Uri.parse("${AppConfig.backendBase}/api/complaints/add-remark/$id"),
            headers: AppConfig.jsonHeaders(token: token),
            body: jsonEncode({"remark": controller.text}),
          );

          Navigator.pop(context);
          _showSnack('Remark added successfully');
          fetchComplaints();
        },
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
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

  List get _filtered {
    return complaints.where((c) {
      final desc = (c['description'] ?? '').toLowerCase();
      final status = (c['status'] ?? '').toLowerCase();
      final user = (c['userId']?['name'] ?? '').toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          desc.contains(_searchQuery.toLowerCase()) ||
          user.contains(_searchQuery.toLowerCase());
      final matchFilter = _filter == 'All' ||
          status == _filter.toLowerCase();
      return matchSearch && matchFilter;
    }).toList();
  }

  int _countByStatus(String s) =>
      complaints.where((c) => (c['status'] ?? '').toLowerCase() == s.toLowerCase()).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _Colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (!loading) _buildStats(),
            _buildSearchAndFilter(),
            Expanded(
              child: loading
                  ? _buildLoader()
                  : filtered.isEmpty
                  ? _buildEmpty()
                  : _buildList(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _Colors.accent.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Admin Console',
                style: TextStyle(
                  color: _Colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Complaint Management',
                style: TextStyle(
                  color: _Colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          _IconBtn(
            icon: Icons.refresh_rounded,
            onTap: fetchComplaints,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
            tooltip: 'Notifications',
            badge: complaints.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          _StatCard(
            label: 'Total',
            value: '${complaints.length}',
            color: _Colors.accent,
            icon: Icons.inbox_rounded,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Pending',
            value: '${_countByStatus('pending')}',
            color: _Colors.warning,
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Resolved',
            value: '${_countByStatus('resolved')}',
            color: _Colors.success,
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: _Colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _Colors.cardBorder, width: 1),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: _Colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search complaints or users...',
                hintStyle: const TextStyle(color: _Colors.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _Colors.textSecondary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _Colors.textSecondary, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final active = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: active ? _Colors.accent : _Colors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? _Colors.accent : _Colors.cardBorder,
                        width: 1,
                      ),
                      boxShadow: active
                          ? [BoxShadow(color: _Colors.accentGlow, blurRadius: 8)]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      f,
                      style: TextStyle(
                        color: active ? Colors.white : _Colors.textSecondary,
                        fontSize: 12,
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

  Widget _buildList(List items) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: items.length,
        itemBuilder: (_, i) => _ComplaintCard(
          complaint: items[i],
          index: i,
          onDelete: () => deleteComplaint(
            items[i]['_id'],
            items[i]['description'] ?? '',
          ),
          onRemark: () => addRemark(items[i]['_id']),
        ),
      ),
    );
  }

  Widget _buildLoader() {
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
            child: const CircularProgressIndicator(
              color: _Colors.accent,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading complaints...',
            style: TextStyle(color: _Colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
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
            child: const Icon(Icons.inbox_rounded, color: _Colors.textMuted, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'No complaints found',
            style: TextStyle(
              color: _Colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: _Colors.textSecondary, fontSize: 13),
          ),
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

  const _ComplaintCard({
    required this.complaint,
    required this.index,
    required this.onDelete,
    required this.onRemark,
  });

  @override
  State<_ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<_ComplaintCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + widget.index * 60),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final hasRemark = (c['remark'] ?? '').toString().isNotEmpty;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _Colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _Colors.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Top accent line
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_Colors.accent, Color(0xFF6366F1)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _Colors.accent.withOpacity(0.8),
                                  const Color(0xFF6366F1).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (c['userId']?['name'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['userId']?['name'] ?? 'Unknown User',
                                  style: const TextStyle(
                                    color: _Colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
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

                      const SizedBox(height: 14),
                      const Divider(color: _Colors.divider, height: 1),
                      const SizedBox(height: 14),

                      // Description
                      Text(
                        c['description'] ?? 'No description provided.',
                        style: const TextStyle(
                          color: _Colors.textPrimary,
                          fontSize: 13.5,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      // Remark (if any)
                      if (hasRemark) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _Colors.accent.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _Colors.accent.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.comment_rounded,
                                  color: _Colors.accent, size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c['remark'],
                                  style: const TextStyle(
                                    color: _Colors.textSecondary,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

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
                          const SizedBox(width: 10),
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
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: iconOnly ? 14 : 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: iconOnly ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(icon, color: color, size: 16),
            if (!iconOnly) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
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

// ─── Icon Button ─────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool badge;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge = false,
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
              Icon(icon, color: _Colors.textSecondary, size: 20),
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

// ─── Delete Dialog ────────────────────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  final String description;
  const _DeleteDialog({required this.description});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _Colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _Colors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: _Colors.danger, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete Complaint?',
              style: TextStyle(
                color: _Colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: const TextStyle(color: _Colors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _Colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _Colors.cardBorder),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _Colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _Colors.danger,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _Colors.dangerGlow,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    color: _Colors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      color: _Colors.accent, size: 20),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Add Remark',
                  style: TextStyle(
                    color: _Colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: _Colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _Colors.cardBorder),
              ),
              child: TextField(
                controller: controller,
                maxLines: 4,
                style: const TextStyle(color: _Colors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Write your remark here...',
                  hintStyle: TextStyle(color: _Colors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _Colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _Colors.cardBorder),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _Colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onSubmit,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _Colors.accentGlow,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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