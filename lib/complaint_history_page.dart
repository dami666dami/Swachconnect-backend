import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'app_text.dart';

// ══════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ══════════════════════════════════════════════════════════════

class _C {
  static const g800 = Color(0xFF1A3C2A);
  static const g700 = Color(0xFF2D5A3D);
  static const g600 = Color(0xFF3E7A53);
  static const g500 = Color(0xFF52A06B);
  static const g400 = Color(0xFF78C28E);
  static const g300 = Color(0xFF9DCFB0);
  static const g200 = Color(0xFFB8DCCA);
  static const g100 = Color(0xFFDFF0E6);
  static const g50  = Color(0xFFF0F8F3);

  static const ink   = Color(0xFF0A1A10);
  static const smoke = Color(0xFF2C3E30);
  static const stone = Color(0xFF5A7060);
  static const fog   = Color(0xFF96AFA0);
  static const cloud = Color(0xFFF2F7F4);
  static const white = Color(0xFFFFFFFF);

  static const gold   = Color(0xFFD4A843);
  static const amber  = Color(0xFFF39C12);
  static const orange = Color(0xFFE67E22);
  static const red    = Color(0xFFD63031);
  static const teal   = Color(0xFF00897B);

  // Status palette
  static const pendingBg   = Color(0xFFFFF8E1);
  static const pendingFg   = Color(0xFFF39C12);
  static const escalatedBg = Color(0xFFFFF3E0);
  static const escalatedFg = Color(0xFFE67E22);
  static const resolvedBg  = Color(0xFFE8F5E9);
  static const resolvedFg  = Color(0xFF2D5A3D);

  // NEW: Remark palette
  static const remarkBg      = Color(0xFFF0F8F3);
  static const remarkBorder  = Color(0xFFB8DCCA);
  static const remarkIconBg  = Color(0xFFDFF0E6);
  static const remarkTitle   = Color(0xFF2D5A3D);
  static const remarkText    = Color(0xFF3A5C45);

  static final LinearGradient primaryGrad = const LinearGradient(
    colors: [g800, g600], begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static final LinearGradient goldGrad = const LinearGradient(
    colors: [Color(0xFFD4A843), Color(0xFFF0C060)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static final LinearGradient orangeGrad = const LinearGradient(
    colors: [Color(0xFFE67E22), Color(0xFFF39C12)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static final LinearGradient tealGrad = const LinearGradient(
    colors: [Color(0xFF00695C), Color(0xFF00897B)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static final LinearGradient redGrad = const LinearGradient(
    colors: [Color(0xFFD63031), Color(0xFFE17055)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // NEW: Remark gradient — subtle left-accent stripe
  static final LinearGradient remarkGrad = const LinearGradient(
    colors: [Color(0xFF3E7A53), Color(0xFF52A06B)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
}

class _T {
  static const h2   = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _C.ink,   letterSpacing: -0.3);
  static const h3   = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.smoke, letterSpacing: -0.1);
  static const body = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _C.stone, height: 1.5);
  static const micro= TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _C.fog,   letterSpacing: 1.4);
  static const label= TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.fog,   letterSpacing: 1.2);
}

// ══════════════════════════════════════════════════════════════
//  ANIMATED PRESS BUTTON
// ══════════════════════════════════════════════════════════════

class _PressBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final BorderRadius? radius;
  final EdgeInsets? padding;

  const _PressBtn({
    required this.child,
    this.onTap,
    this.gradient,
    this.color,
    this.radius,
    this.padding,
  });

  @override
  State<_PressBtn> createState() => _PressBtnState();
}

class _PressBtnState extends State<_PressBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.lightImpact(); _ctrl.forward(); },
      onTapUp:   (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            color: widget.gradient == null ? widget.color : null,
            borderRadius: widget.radius ?? BorderRadius.circular(14),
            boxShadow: widget.onTap == null ? null : [
              BoxShadow(
                color: (widget.color ?? const Color(0xFF2D5A3D)).withValues(alpha: 0.22),
                blurRadius: 14, offset: const Offset(0, 5),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ANIMATED PROGRESS BAR
// ══════════════════════════════════════════════════════════════

class _AnimatedProgress extends StatefulWidget {
  final double value;
  final Color color;
  final Color bg;

  const _AnimatedProgress({required this.value, required this.color, required this.bg});

  @override
  State<_AnimatedProgress> createState() => _AnimatedProgressState();
}

class _AnimatedProgressState extends State<_AnimatedProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Stack(children: [
        Container(height: 8, decoration: BoxDecoration(color: widget.bg, borderRadius: BorderRadius.circular(8))),
        FractionallySizedBox(
          widthFactor: _anim.value.clamp(0.0, 1.0),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [widget.color.withValues(alpha: 0.7), widget.color]),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.40), blurRadius: 6, offset: const Offset(0, 2))],
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ESCALATION TIMELINE
// ══════════════════════════════════════════════════════════════

class _EscalationTimeline extends StatelessWidget {
  final int current;
  final int total;

  const _EscalationTimeline({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total * 2 - 1, (i) {
        if (i.isOdd) {
          final filled = (i ~/ 2) < current;
          return Expanded(child: Container(height: 2, color: filled ? _C.g500 : _C.g100));
        }
        final idx    = i ~/ 2;
        final done   = idx < current;
        final active = idx == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: active ? 12 : 8, height: active ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? _C.g500 : active ? _C.gold : _C.g100,
            boxShadow: active ? [BoxShadow(color: _C.gold.withValues(alpha: 0.5), blurRadius: 6)] : null,
          ),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STATUS CHIP
// ══════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late IconData icon;
    late String label;

    switch (status.toLowerCase()) {
      case 'resolved':
        bg = _C.resolvedBg; fg = _C.resolvedFg; icon = Icons.check_circle_rounded; label = "RESOLVED";
        break;
      case 'escalated':
        bg = _C.escalatedBg; fg = _C.escalatedFg; icon = Icons.trending_up_rounded; label = "ESCALATED";
        break;
      default:
        bg = _C.pendingBg; fg = _C.pendingFg; icon = Icons.hourglass_bottom_rounded; label = "PENDING";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: fg, size: 13),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  NEW: AUTHORITY REMARK WIDGET
//  Displays a one-way message from authority to user.
//  Only shown when remark is non-null and non-empty.
// ══════════════════════════════════════════════════════════════

class _AuthorityRemark extends StatefulWidget {
  final String remark;

  const _AuthorityRemark({required this.remark});

  @override
  State<_AuthorityRemark> createState() => _AuthorityRemarkState();
}

class _AuthorityRemarkState extends State<_AuthorityRemark>
    with SingleTickerProviderStateMixin {
  // NEW: Fade-in animation for the remark box
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    // Small delay so it appears after the card settles
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // NEW: Animated fade + slide-up for the remark section
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          decoration: BoxDecoration(
            color: _C.remarkBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.remarkBorder),
            boxShadow: [
              BoxShadow(
                color: _C.g800.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // NEW: Left green accent stripe
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: _C.remarkGrad,
                  borderRadius: const BorderRadius.only(
                    topLeft:    Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),

              // NEW: Remark content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // NEW: Header row — icon + label
                    Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _C.remarkIconBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.comment_bank_outlined, color: _C.g600, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "AUTHORITY REMARK",
                        style: _T.label.copyWith(color: _C.remarkTitle, letterSpacing: 1.0),
                      ),
                    ]),

                    const SizedBox(height: 10),

                    // NEW: Divider
                    Container(height: 1, color: _C.remarkBorder),

                    const SizedBox(height: 10),

                    // NEW: Remark text
                    Text(
                      widget.remark,
                      style: _T.body.copyWith(
                        color: _C.remarkText,
                        fontSize: 13.5,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STAGGERED CARD ANIMATION WRAPPER
// ══════════════════════════════════════════════════════════════

class _StaggerCard extends StatefulWidget {
  final Widget child;
  final int index;

  const _StaggerCard({required this.child, required this.index});

  @override
  State<_StaggerCard> createState() => _StaggerCardState();
}

class _StaggerCardState extends State<_StaggerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: 80 + widget.index * 90), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ══════════════════════════════════════════════════════════════
//  EMPTY STATE
// ══════════════════════════════════════════════════════════════

class _EmptyState extends StatefulWidget {
  const _EmptyState();
  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -10)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedBuilder(
        animation: _bounce,
        builder: (_, child) => Transform.translate(offset: Offset(0, _bounce.value), child: child),
        child: Container(
          width: 96, height: 96,
          decoration: BoxDecoration(color: _C.g50, shape: BoxShape.circle, border: Border.all(color: _C.g100, width: 2)),
          child: const Icon(Icons.inbox_outlined, size: 44, color: _C.g300),
        ),
      ),
      const SizedBox(height: 24),
      Text(AppText.t("noComplaints"), style: _T.h2.copyWith(color: _C.smoke)),
      const SizedBox(height: 8),
      Text("Your reported complaints will appear here.", style: _T.body),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════
//  LOADING STATE
// ══════════════════════════════════════════════════════════════

class _LoadingState extends StatefulWidget {
  const _LoadingState();
  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rot;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _rot  = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AnimatedBuilder(
        animation: _rot,
        builder: (_, child) => Transform.rotate(angle: _rot.value * 2 * math.pi, child: child),
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _C.primaryGrad,
            boxShadow: [BoxShadow(color: _C.g800.withValues(alpha: 0.25), blurRadius: 14)],
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text("Loading your complaints…", style: _T.body),
    ],
  );
}

// ══════════════════════════════════════════════════════════════
//  HERO BG PAINTER
// ══════════════════════════════════════════════════════════════

class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p  = Paint()..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), size.width * 0.4, p);
    canvas.drawCircle(Offset(size.width * 0.1,  size.height * 0.9), size.width * 0.3, p);
    final dp = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (double x = 0; x < size.width;  x += 28)
      for (double y = 0; y < size.height; y += 28)
        canvas.drawCircle(Offset(x, y), 1.5, dp);
  }
  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
//  MINI STAT PILL
// ══════════════════════════════════════════════════════════════

class _MiniStat extends StatelessWidget {
  final int    count;
  final String label;
  final Color  color;

  const _MiniStat({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: Column(children: [
      Text("$count", style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900, height: 1.0)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════
//  FILTER BAR
// ══════════════════════════════════════════════════════════════

class _FilterBar extends StatelessWidget {
  final String          selected;
  final List<String>    options;
  final ValueChanged<String> onSelect;

  const _FilterBar({required this.selected, required this.options, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: options.map((opt) {
          final active = opt == selected;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onSelect(opt); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: active ? _C.primaryGrad : null,
                color: active ? null : _C.g50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? Colors.transparent : _C.g200),
                boxShadow: active
                    ? [BoxShadow(color: _C.g800.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Text(opt, style: TextStyle(
                color: active ? Colors.white : _C.stone,
                fontSize: 12, fontWeight: FontWeight.w700,
              )),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  BOTTOM SHEET
// ══════════════════════════════════════════════════════════════

class _BottomSheet extends StatelessWidget {
  final String    title, body, cancelLabel, confirmLabel;
  final IconData  icon;
  final Color     iconColor;
  final Gradient  confirmGrad;
  final VoidCallback onConfirm;

  const _BottomSheet({
    required this.title,
    required this.body,
    required this.icon,
    required this.iconColor,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmGrad,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: _C.g200, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title, style: _T.h2, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body, style: _T.body, textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: _C.g50, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.g200)),
                  child: Text(cancelLabel, textAlign: TextAlign.center, style: _T.h3.copyWith(color: _C.stone)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PressBtn(
                gradient: confirmGrad,
                radius: BorderRadius.circular(14),
                padding: const EdgeInsets.symmetric(vertical: 15),
                onTap: () { Navigator.pop(context); onConfirm(); },
                child: Text(confirmLabel, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ]),
        ]),
      ),),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  COMPLAINT CARD
//  CHANGE: Added `remark` field extraction and _AuthorityRemark
//  widget render inside the expanded details section.
// ══════════════════════════════════════════════════════════════

class _ComplaintCard extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final List<String>         authorityLevels;
  final bool                 escalating;
  final void Function(Map<String, dynamic>) onDelete;
  final void Function(Map<String, dynamic>) onEscalate;
  final void Function(Map<String, dynamic>) onShare;
  final bool Function(String?)              isDeadlinePassed;

  const _ComplaintCard({
    required this.complaint,
    required this.authorityLevels,
    required this.escalating,
    required this.onDelete,
    required this.onEscalate,
    required this.onShare,
    required this.isDeadlinePassed,
  });

  @override
  State<_ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<_ComplaintCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandCtrl;
  late Animation<double>   _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _expandCtrl.dispose(); super.dispose(); }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
    _expanded ? _expandCtrl.forward() : _expandCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;

    final bool resolved        = c['status'] == "Resolved";
    final bool deadlinePassed  = widget.isDeadlinePassed(c['deadline']);
    final int  escalationLevel = c['escalationLevel'] ?? 0;
    final bool finalEscalation = escalationLevel >= widget.authorityLevels.length - 1;
    final bool isAnonymous     = c['isAnonymous'] == true || c['isAnonymous'] == "true";
    final int  progress        = (c['progress'] ?? 0) as int;
    final String date          = (c['createdAt'] ?? '').toString().length >= 10
        ? (c['createdAt'] as String).substring(0, 10) : '—';

    // NEW: Safely extract remark — null if absent or blank
    final String? remark = () {
      final raw = c['remark'];
      if (raw == null) return null;
      final str = raw.toString().trim();
      return str.isEmpty ? null : str;
    }();

    late Color progressColor;
    switch (c['status']) {
      case 'Resolved':  progressColor = _C.g500;   break;
      case 'Escalated': progressColor = _C.orange;  break;
      default:          progressColor = _C.amber;
    }

    late LinearGradient stripeGrad;
    if (resolved)              { stripeGrad = _C.primaryGrad; }
    else if (c['status'] == 'Escalated') { stripeGrad = _C.orangeGrad; }
    else                       { stripeGrad = _C.goldGrad; }

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: _C.g800.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Colour accent stripe ──
            Container(height: 4, decoration: BoxDecoration(gradient: stripeGrad)),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Top row ──
                Row(children: [
                  _StatusChip(status: c['status'] ?? 'Pending'),
                  const Spacer(),
                  if (isAnonymous)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(color: _C.g50, borderRadius: BorderRadius.circular(7), border: Border.all(color: _C.g200)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.shield_outlined, size: 12, color: _C.g500),
                        const SizedBox(width: 4),
                        Text(AppText.t("anonymous"), style: _T.label.copyWith(color: _C.g600)),
                      ]),
                    ),
                  if (c['status'] == 'Pending')
                    GestureDetector(
                      onTap: () => widget.onDelete(c),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.delete_outline_rounded, color: _C.red, size: 17),
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 280),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: _C.g50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: _C.stone, size: 18),
                    ),
                  ),
                ]),

                const SizedBox(height: 14),

                // ── Authority ──
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: _C.g50, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.account_balance_outlined, color: _C.g600, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Assigned Authority", style: _T.label),
                    const SizedBox(height: 2),
                    Text(c['assignedAuthority'] ?? 'N/A', style: _T.h3.copyWith(fontSize: 13)),
                  ])),
                ]),

                const SizedBox(height: 14),

                // ── Progress bar ──
                Row(children: [
                  Expanded(child: _AnimatedProgress(value: progress / 100, color: progressColor, bg: _C.g100)),
                  const SizedBox(width: 10),
                  Text("$progress%", style: _T.h3.copyWith(color: progressColor, fontSize: 13)),
                ]),

                const SizedBox(height: 14),

                // ── Escalation timeline ──
                _EscalationTimeline(
                  current: escalationLevel.clamp(0, widget.authorityLevels.length - 1),
                  total: widget.authorityLevels.length,
                ),

                const SizedBox(height: 6),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("Level $escalationLevel / ${widget.authorityLevels.length - 1}", style: _T.label),
                  Text("Filed: $date", style: _T.label),
                ]),

                const SizedBox(height: 14),
              ]),
            ),

            // ── Expandable details ──
            SizeTransition(
              sizeFactor: _expandAnim,
              child: ClipRect(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Existing details box
                      Container(
                        margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _C.g50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _C.g100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Details", style: _T.label.copyWith(color: _C.g700)),
                            const SizedBox(height: 10),

                            if (c['description'] != null)
                              Text(c['description'].toString(), style: _T.body),

                            if (c['location'] != null) ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: _C.g500),
                                const SizedBox(width: 5),
                                Text(
                                  "${c['location']['lat']?.toStringAsFixed(4) ?? '?'}, "
                                      "${c['location']['lng']?.toStringAsFixed(4) ?? '?'}",
                                  style: _T.body.copyWith(fontSize: 12),
                                ),
                              ]),
                            ],

                            if (c['deadline'] != null) ...[
                              const SizedBox(height: 6),
                              Row(children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 14,
                                  color: deadlinePassed ? _C.red : _C.g500,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Deadline: ${(c['deadline'] as String).substring(0, 10)}",
                                  style: _T.body.copyWith(
                                    fontSize: 12,
                                    color: deadlinePassed ? _C.red : _C.stone,
                                  ),
                                ),
                                if (deadlinePassed) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF0F0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "OVERDUE",
                                      style: _T.micro.copyWith(
                                        color: _C.red,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ]),
                            ],
                          ],
                        ),
                      ),

                      // ✅ Authority Remark Section
                      if (remark != null && remark.toString().trim().isNotEmpty) ...[
                        _AuthorityRemark(remark: remark),
                      ],

                    ],
                  ),
                ),
              ),
            ),

            // ── Escalate button ──
            if (deadlinePassed && !resolved && !finalEscalation)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: _PressBtn(
                  gradient: _C.orangeGrad,
                  radius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onTap: widget.escalating ? null : () => widget.onEscalate(c),
                  child: SizedBox(
                    width: double.infinity,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      widget.escalating
                          ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.trending_up_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(AppText.t("escalate"),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    ]),
                  ),
                ),
              ),

            // ── Share awareness button ──
            if (deadlinePassed && !resolved && finalEscalation)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: _PressBtn(
                  gradient: _C.tealGrad,
                  radius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onTap: () => widget.onShare(c),
                  child: SizedBox(
                    width: double.infinity,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.campaign_outlined, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(AppText.t("shareAwareness"),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  MAIN PAGE  (unchanged)
// ══════════════════════════════════════════════════════════════

class ComplaintHistoryPage extends StatefulWidget {
  const ComplaintHistoryPage({super.key});

  @override
  State<ComplaintHistoryPage> createState() => _ComplaintHistoryPageState();
}

class _ComplaintHistoryPageState extends State<ComplaintHistoryPage>
    with SingleTickerProviderStateMixin {
  bool loading = true;
  List<Map<String, dynamic>> complaints = [];

  Timer? _autoRefreshTimer;
  bool   _escalating = false;

  late AnimationController _headerCtrl;
  late Animation<double>   _headerFade;

  String _filter = "All";
  final _filters = ["All", "Pending", "Escalated", "Resolved"];

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
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();
    fetchComplaints();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) fetchComplaints();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _headerCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == "All") return complaints;
    return complaints
        .where((c) => (c['status'] ?? '').toString().toLowerCase() == _filter.toLowerCase())
        .toList();
  }

  int get _pending   => complaints.where((c) => c['status'] == 'Pending').length;
  int get _escalated => complaints.where((c) => c['status'] == 'Escalated').length;
  int get _resolved  => complaints.where((c) => c['status'] == 'Resolved').length;

  Future<void> fetchComplaints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);
      if (token == null) { if (mounted) setState(() => loading = false); return; }
      final res = await http.get(
        Uri.parse("${AppConfig.backendBase}/api/complaints/my"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() { complaints = data.cast<Map<String, dynamic>>(); loading = false; });
      } else {
        setState(() => loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  void confirmDelete(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        title: AppText.t("deleteComplaint"),
        body: AppText.t("deleteConfirm"),
        icon: Icons.delete_outline_rounded,
        iconColor: _C.red,
        cancelLabel: AppText.t("cancel"),
        confirmLabel: AppText.t("delete"),
        confirmGrad: _C.redGrad,
        onConfirm: () => deleteComplaint(c['_id']),
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
      _showSnack(
        res.statusCode == 200 ? AppText.t("deleteSuccess") : AppText.t("deleteFailed"),
        isError: res.statusCode != 200,
      );
      fetchComplaints();
    } catch (_) {}
  }

  bool isDeadlinePassed(String? deadline) {
    if (deadline == null) return false;
    try { return DateTime.now().isAfter(DateTime.parse(deadline)); } catch (_) { return false; }
  }

  void confirmEscalation(Map<String, dynamic> complaint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        title: AppText.t("escalateComplaint"),
        body: "${AppText.t("currentAuthority")}:\n"
            "${complaint['assignedAuthority'] ?? 'N/A'}\n\n"
            "${AppText.t("deadlinePassed")}\n\n"
            "${AppText.t("confirmEscalate")}",
        icon: Icons.trending_up_rounded,
        iconColor: _C.orange,
        cancelLabel: AppText.t("wait"),
        confirmLabel: AppText.t("escalate"),
        confirmGrad: _C.orangeGrad,
        onConfirm: () => escalateComplaint(complaint),
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
        Uri.parse("${AppConfig.backendBase}/api/complaints/escalate/${complaint['_id']}"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _showSuccessDialog(AppText.t("escalationConfirmed"), AppText.t("escalationSuccess"));
      } else {
        _showSnack(AppText.t("escalationFailed"), isError: true);
      }
      fetchComplaints();
    } catch (_) {}
    finally { if (mounted) setState(() => _escalating = false); }
  }

  void confirmSocialShare(Map<String, dynamic> complaint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        title: "Raise Public Awareness",
        body: "This complaint has reached the highest authority and remains unresolved.\n\nShare it publicly to rally community support.",
        icon: Icons.campaign_outlined,
        iconColor: _C.teal,
        cancelLabel: "Cancel",
        confirmLabel: "Share Now",
        confirmGrad: _C.tealGrad,
        onConfirm: () => _doShare(complaint),
      ),
    );
  }

  void _doShare(Map<String, dynamic> c) {
    final lat       = c['location']?['lat']?.toString() ?? "N/A";
    final lng       = c['location']?['lng']?.toString() ?? "N/A";
    final date      = c['createdAt']?.toString().substring(0, 10) ?? "Unknown";
    final authority = c['assignedAuthority'] ?? "Authority";
    Share.share(
      '🚯 Unresolved Waste Issue\n\nReported via SwachConnect\n\n'
          '📍 Location: $lat, $lng\n🕒 Reported on: $date\n'
          '🏛 Assigned Authority: $authority\n\n'
          'This issue remains unresolved despite escalation.\n\n'
          '#SwachConnect #CleanCities #WasteManagement',
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: isError ? _C.red : _C.g700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      elevation: 0,
    ));
  }

  void _showSuccessDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: _C.primaryGrad, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _C.g800.withValues(alpha: 0.30), blurRadius: 16)],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            Text(title, style: _T.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body, style: _T.body, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            _PressBtn(
              gradient: _C.primaryGrad,
              radius: BorderRadius.circular(14),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              onTap: () => Navigator.pop(context),
              child: Text(AppText.t("ok"),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cloud,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: _C.g800,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: FadeTransition(
                opacity: _headerFade,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppText.t("myComplaints"),
                        style: const TextStyle(color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                    Text("${complaints.length} reports filed",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
                  ],
                ),
              ),
              background: Stack(fit: StackFit.expand, children: [
                Container(decoration: BoxDecoration(gradient: _C.primaryGrad)),
                Positioned.fill(child: CustomPaint(painter: _HeroBgPainter())),
                Positioned(
                  top: 60, right: 20,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: Row(children: [
                      _MiniStat(count: _pending,   label: "Pending",   color: _C.gold),
                      const SizedBox(width: 8),
                      _MiniStat(count: _escalated, label: "Escalated", color: _C.orange),
                      const SizedBox(width: 8),
                      _MiniStat(count: _resolved,  label: "Resolved",  color: _C.g400),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ],
        body: loading
            ? const Center(child: _LoadingState())
            : Column(children: [
          _FilterBar(selected: _filter, options: _filters, onSelect: (v) => setState(() => _filter = v)),
          Expanded(
            child: _filtered.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              color: _C.g700,
              onRefresh: fetchComplaints,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _filtered.length,
                itemBuilder: (_, i) => _StaggerCard(
                  index: i,
                  child: _ComplaintCard(
                    complaint: _filtered[i],
                    authorityLevels: authorityLevels,
                    escalating: _escalating,
                    onDelete: confirmDelete,
                    onEscalate: confirmEscalation,
                    onShare: confirmSocialShare,
                    isDeadlinePassed: isDeadlinePassed,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}