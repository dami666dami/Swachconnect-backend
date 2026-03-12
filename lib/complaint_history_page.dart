import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'app_text.dart';

class ComplaintHistoryPage extends StatefulWidget {
  const ComplaintHistoryPage({super.key});

  @override
  State<ComplaintHistoryPage> createState() => _ComplaintHistoryPageState();
}

class _ComplaintHistoryPageState extends State<ComplaintHistoryPage> {
  bool loading = true;
  List<Map<String, dynamic>> complaints = [];

  Timer? _autoRefreshTimer;
  bool _escalating = false;

  final List<String> authorityLevels = [
    "Municipality / Panchayat",
    "Ward Councillor",
    "District Health Officer",
    "Pollution Control Board",
    "District Collector",
    "State Health Department",
    "National Authorities",
  ];

  @override
  void initState() {
    super.initState();
    fetchComplaints();

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
          (_) {
        if (mounted) fetchComplaints();
      },
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  /* ================= FETCH ================= */

  Future<void> fetchComplaints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);

      if (token == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final res = await http.get(
        Uri.parse("${AppConfig.backendBase}/api/complaints/my"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          complaints = data.cast<Map<String, dynamic>>();
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  /* ================= DELETE ================= */

  void confirmDelete(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppText.t("deleteComplaint")),
        content: Text(AppText.t("deleteConfirm")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppText.t("cancel")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              deleteComplaint(c['_id']);
            },
            child: Text(AppText.t("delete")),
          ),
        ],
      ),
    );
  }

  Future<void> deleteComplaint(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);
      if (token == null) return;

      final res = await http.delete(
        Uri.parse("${AppConfig.backendBase}/api/complaints/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.statusCode == 200
                ? AppText.t("deleteSuccess")
                : AppText.t("deleteFailed"),
          ),
        ),
      );

      fetchComplaints();
    } catch (_) {}
  }

  /* ================= HELPERS ================= */

  bool isDeadlinePassed(String? deadline) {
    if (deadline == null) return false;
    try {
      return DateTime.now().isAfter(DateTime.parse(deadline));
    } catch (_) {
      return false;
    }
  }

  /* ================= ESCALATION ================= */

  void confirmEscalation(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppText.t("escalateComplaint")),
        content: Text(
          "${AppText.t("currentAuthority")}:\n${complaint['assignedAuthority'] ?? 'N/A'}\n\n"
              "${AppText.t("deadlinePassed")}\n\n"
              "${AppText.t("confirmEscalate")}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppText.t("wait")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              escalateComplaint(complaint);
            },
            child: Text(AppText.t("escalate")),
          ),
        ],
      ),
    );
  }

  Future<void> escalateComplaint(Map<String, dynamic> complaint) async {
    if (_escalating) return;
    setState(() => _escalating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);
      if (token == null) return;

      final res = await http.put(
        Uri.parse(
          "${AppConfig.backendBase}/api/complaints/escalate/${complaint['_id']}",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              AppText.t("escalationConfirmed"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(AppText.t("escalationSuccess")),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppText.t("ok")),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.t("escalationFailed"))),
        );
      }

      fetchComplaints();
    } catch (_) {}
    finally {
      if (mounted) setState(() => _escalating = false);
    }
  }

  /* ================= SOCIAL MEDIA ESCALATION ================= */

  void confirmSocialShare(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Social Media Escalation"),
        content: const Text(
          "This complaint has reached the highest authority and remains unresolved.\n\n"
              "Would you like to share this issue publicly to raise awareness?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              shareOnInstagram(complaint);
            },
            child: const Text("Share"),
          ),
        ],
      ),
    );
  }

  void shareOnInstagram(Map<String, dynamic> c) {
    final lat = c['location']?['lat']?.toString() ?? "N/A";
    final lng = c['location']?['lng']?.toString() ?? "N/A";
    final date = c['createdAt']?.toString().substring(0, 10) ?? "Unknown";
    final authority = c['assignedAuthority'] ?? "Authority";

    Share.share('''
🚯 Unresolved Waste Issue

Reported via SwachConnect

📍 Location: $lat, $lng
🕒 Reported on: $date
🏛 Assigned Authority: $authority

This issue remains unresolved despite escalation.

Help raise awareness for cleaner communities.

#SwachConnect #CleanCities #WasteManagement
''');
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppText.t("myComplaints"))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : complaints.isEmpty
          ? Center(child: Text(AppText.t("noComplaints")))
          : RefreshIndicator(
        onRefresh: fetchComplaints,
        child: ListView.builder(
          itemCount: complaints.length,
          itemBuilder: (_, i) => _complaintCard(complaints[i]),
        ),
      ),
    );
  }

  /* ================= CARD ================= */

  Widget _complaintCard(Map<String, dynamic> c) {
    final bool resolved = c['status'] == "Resolved";
    final bool deadlinePassed = isDeadlinePassed(c['deadline']);
    final int escalationLevel = c['escalationLevel'] ?? 0;
    final bool finalEscalation =
        escalationLevel >= authorityLevels.length - 1;

    final bool isAnonymous =
        c['isAnonymous'] == true || c['isAnonymous'] == "true";

    Color statusColor = resolved
        ? Colors.green
        : c['status'] == "Escalated"
        ? Colors.orange
        : Colors.amber;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (c['status'] ?? "UNKNOWN").toString().toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isAnonymous)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(AppText.t("anonymous")),
                    backgroundColor: Colors.black12,
                  ),
                ),
              if (c['status'] == "Pending")
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDelete(c),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text("${AppText.t("authority")}: ${c['assignedAuthority'] ?? 'N/A'}"),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ((c['progress'] ?? 0) as int) / 100,
            valueColor: AlwaysStoppedAnimation(statusColor),
          ),
          const SizedBox(height: 8),
          Text("${AppText.t("progress")}: ${c['progress'] ?? 0}%"),
          const SizedBox(height: 12),

          if (deadlinePassed && !resolved && !finalEscalation)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: _escalating ? null : () => confirmEscalation(c),
              child: _escalating
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(AppText.t("escalate")),
            ),

          if (deadlinePassed && !resolved && finalEscalation)
            OutlinedButton(
              onPressed: () => confirmSocialShare(c),
              child: Text(AppText.t("shareAwareness")),
            ),
        ],
      ),
    );
  }
}