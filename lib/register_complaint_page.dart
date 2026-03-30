import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exif/exif.dart';

import 'config.dart';
import 'app_text.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
//  Fix: removed unused fields g900, g600, g400, g100, dim
// ─────────────────────────────────────────────────────────────
class _T {
  static const g800 = Color(0xFF2E7D32);
  static const g50  = Color(0xFFE8F5E9);

  static const bg   = Color(0xFFF0F4F2);
  static const card = Color(0xFFFFFFFF);
  static const tx   = Color(0xFF111111);
  static const sub  = Color(0xFF6B7280);
  static const brd  = Color(0x14000000);

  static const errBg  = Color(0xFFFFEBEE);
  static const errTx  = Color(0xFFC62828);
  static const warnBg = Color(0xFFFFF3E0);
  static const warnTx = Color(0xFFE65100);
  static const okBg   = Color(0xFFE8F5E9);
  static const okTx   = Color(0xFF2E7D32);

  static const rXL = Radius.circular(20);
  static const rL  = Radius.circular(16);
  static const rM  = Radius.circular(12);
  static const rS  = Radius.circular(8);

  // Fix: replaced deprecated .withOpacity() with .withValues(alpha:)
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────
//  TOAST TYPE
// ─────────────────────────────────────────────────────────────
enum _ToastType { info, success, error }

// ─────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────
class RegisterComplaintPage extends StatefulWidget {
  const RegisterComplaintPage({super.key});

  @override
  State<RegisterComplaintPage> createState() => _RegisterComplaintPageState();
}

class _RegisterComplaintPageState extends State<RegisterComplaintPage>
    with TickerProviderStateMixin {
  final _descCtrl  = TextEditingController();
  final _descFocus = FocusNode();
  final List<File> _images = [];

  double? _lat, _lng;
  bool _loading           = false;
  bool _locationLoading   = false;
  bool _locationConfirmed = false;

  late AnimationController _pageAnim;
  late AnimationController _submitPulse;
  late Animation<double>   _pageFade;
  late Animation<Offset>   _pageSlide;

  final _backendBase = AppConfig.backendBase;

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _submitPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.97,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _pageFade = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut));

    _pageAnim.forward();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _descFocus.dispose();
    _pageAnim.dispose();
    _submitPulse.dispose();
    super.dispose();
  }

  // ─── LOCATION ─────────────────────────────────────────────
  void _resetLocation() => setState(() {
    _lat = _lng = null;
    _locationConfirmed = false;
  });

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _locationLoading   = true;
      _locationConfirmed = false;
    });
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _toast('Location permission denied', type: _ToastType.error);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (_) {
      _toast('Unable to fetch location', type: _ToastType.error);
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _openMap() async {
    if (_lat == null || _lng == null) return;
    final url = 'https://www.google.com/maps/search/?api=1&query=$_lat,$_lng';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    _toast('Adjust location in Maps, then return to confirm');
  }

  // ─── IMAGES ───────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 5) {
      _toast('Maximum 5 images allowed', type: _ToastType.error);
      return;
    }
    final picked =
    await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final file = File(picked.path);
    setState(() => _images.add(file));
    if (source == ImageSource.gallery) await _extractLocationFromImage(file);
    HapticFeedback.lightImpact();
  }

  Future<void> _extractLocationFromImage(File file) async {
    try {
      final tags = await readExifFromBytes(await file.readAsBytes());
      if (!tags.containsKey('GPS GPSLatitude') ||
          !tags.containsKey('GPS GPSLongitude')) return;

      // Fix: renamed _dms → dms (local functions must not start with _)
      double dms(List<dynamic> vals) =>
          vals[0].toDouble() +
              vals[1].toDouble() / 60 +
              vals[2].toDouble() / 3600;

      setState(() {
        _lat = dms(tags['GPS GPSLatitude']!.values.toList());
        _lng = dms(tags['GPS GPSLongitude']!.values.toList());
        _locationConfirmed = false;
      });
      _toast('Location extracted from photo');
    } catch (_) {}
  }

  void _removeImage(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _images.removeAt(index);
      if (_images.isEmpty) _resetLocation();
    });
  }

  // ─── SUBMIT ───────────────────────────────────────────────
  Future<void> _onSubmitTap() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (_images.isEmpty) {
      _toast('Add at least one photo', type: _ToastType.error);
      return;
    }
    if (_descCtrl.text.trim().length < 5) {
      _toast('Enter a proper description', type: _ToastType.error);
      _descFocus.requestFocus();
      return;
    }
    if (!_locationConfirmed) {
      _toast('Please confirm location first', type: _ToastType.error);
      return;
    }
    final anon = await _showAnonSheet();
    if (anon != null) await _submitComplaint(isAnonymous: anon);
  }

  Future<bool?> _showAnonSheet() => showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    // Fix: const constructor now possible
    builder: (_) => const _AnonSheet(),
  );

  Future<void> _submitComplaint({bool isAnonymous = false}) async {
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);
      if (token == null) {
        _toast('Session expired. Please login again.',
            type: _ToastType.error);
        return;
      }

      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendBase/api/complaints'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields.addAll({
          'description': _descCtrl.text.trim(),
          'lat': _lat!.toString(),
          'lng': _lng!.toString(),
          'isAnonymous': isAnonymous.toString(),
        });

      for (final img in _images) {
        req.files.add(await http.MultipartFile.fromPath('image', img.path));
      }

      final res = await http.Response.fromStream(await req.send());
      if (!mounted) return;

      if (res.statusCode == 201) {
        HapticFeedback.heavyImpact();
        final data = json.decode(res.body) as Map<String, dynamic>;
        _toast(
          (data['duplicateWarning'] as String?) ?? 'Complaint submitted!',
          type: _ToastType.success,
        );
        Navigator.pop(context);
      } else {
        final data = json.decode(res.body) as Map<String, dynamic>?;
        _toast(
          (data?['message'] as String?) ?? 'Submission failed. Try again.',
          type: _ToastType.error,
        );
      }
    } catch (_) {
      _toast(AppText.t('networkError'), type: _ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── TOAST ────────────────────────────────────────────────
  void _toast(String msg, {_ToastType type = _ToastType.info}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(_toastIcon(type), color: Colors.white, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ]),
        backgroundColor: _toastColor(type),
        behavior: SnackBarBehavior.floating,
        // Fix: const RoundedRectangleBorder
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(_T.rM),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: Duration(seconds: type == _ToastType.error ? 3 : 2),
        elevation: 0,
      ));
  }

  IconData _toastIcon(_ToastType t) => switch (t) {
    _ToastType.error   => Icons.error_outline_rounded,
    _ToastType.success => Icons.check_circle_outline_rounded,
    _ToastType.info    => Icons.info_outline_rounded,
  };

  Color _toastColor(_ToastType t) => switch (t) {
    _ToastType.error   => _T.errTx,
    _ToastType.success => _T.g800,
    _ToastType.info    => const Color(0xFF1A1A2E),
  };

  // ─── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(
          position: _pageSlide,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 8, 16, 120 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fix: const constructors for stateless widgets
                const _Section(
                  icon: Icons.photo_library_outlined,
                  title: 'Photos',
                  subtitle: 'Add up to 5 images of the issue',
                ),
                const SizedBox(height: 12),
                _buildImageCard(),
                const SizedBox(height: 26),
                const _Section(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  subtitle: 'Verify the incident location',
                ),
                const SizedBox(height: 12),
                _buildLocationCard(),
                const SizedBox(height: 26),
                const _Section(
                  icon: Icons.description_outlined,
                  title: 'Description',
                  subtitle: 'Describe the issue in detail',
                ),
                const SizedBox(height: 12),
                _buildDescCard(),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: _buildBottomBar(bottom),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: _T.card,
    surfaceTintColor: _T.card,
    leading: Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          decoration: const BoxDecoration(
            color: _T.bg,
            borderRadius: BorderRadius.all(_T.rS),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 17,
            color: _T.tx,
          ),
        ),
      ),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppText.t('registerComplaint'),
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: _T.tx),
        ),
        const Text(
          'Report an environmental issue',
          style: TextStyle(
              fontSize: 12,
              color: _T.sub,
              fontWeight: FontWeight.w400),
        ),
      ],
    ),
    centerTitle: false,
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: ColoredBox(color: _T.brd, child: SizedBox(height: 1)),
    ),
  );

  // ─── IMAGE CARD ───────────────────────────────────────────
  Widget _buildImageCard() {
    final remaining = 5 - _images.length;
    final canAdd    = remaining > 0;

    // Fix (line 356): padding value depends on runtime state → not const
    final topPad = _images.isEmpty ? 14.0 : 0.0;

    return _Card(
      child: Column(children: [
        if (_images.isNotEmpty) ...[
          SizedBox(
            height: 110,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _buildThumb(i),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Padding(
          // EdgeInsets.fromLTRB is not const here because topPad is a variable
          padding: EdgeInsets.fromLTRB(14, topPad, 14, 14),
          child: _AddPhotoButton(
            canAdd: canAdd,
            label: canAdd
                ? 'Add Photo  ($remaining remaining)'
                : 'Maximum 5 images added',
            onTap: canAdd ? _showPickerSheet : null,
          ),
        ),
      ]),
    );
  }

  Widget _buildThumb(int i) {
    return Stack(children: [
      ClipRRect(
        borderRadius: const BorderRadius.all(_T.rL),
        child: Image.file(_images[i], width: 110, height: 110, fit: BoxFit.cover),
      ),
      Positioned(
        bottom: 6, left: 6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: const BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.all(_T.rS),
          ),
          child: Text(
            '${i + 1}/${_images.length}',
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      Positioned(
        top: 6, right: 6,
        child: GestureDetector(
          onTap: () => _removeImage(i),
          child: Container(
            width: 26, height: 26,
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
          ),
        ),
      ),
    ]);
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        onCamera:  () { Navigator.pop(context); _pickImage(ImageSource.camera); },
        onGallery: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
      ),
    );
  }

  // ─── LOCATION CARD ────────────────────────────────────────
  Widget _buildLocationCard() {
    final hasLoc = _lat != null && _lng != null;

    final Color    statusBg;
    final Color    statusFg;
    final IconData statusIcon;
    final String   statusTitle;

    if (_locationLoading) {
      statusBg    = _T.warnBg;
      statusFg    = _T.warnTx;
      statusIcon  = Icons.my_location_rounded;
      statusTitle = 'Fetching location…';
    } else if (_locationConfirmed) {
      statusBg    = _T.okBg;
      statusFg    = _T.okTx;
      statusIcon  = Icons.check_circle_rounded;
      statusTitle = 'Location Confirmed';
    } else if (hasLoc) {
      statusBg    = _T.warnBg;
      statusFg    = _T.warnTx;
      statusIcon  = Icons.location_searching_rounded;
      statusTitle = 'Location Detected';
    } else {
      statusBg    = _T.errBg;
      statusFg    = _T.errTx;
      statusIcon  = Icons.location_disabled_rounded;
      statusTitle = 'Location Unavailable';
    }

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: const BorderRadius.all(_T.rM),
            ),
            child: Row(children: [
              _locationLoading
                  ? SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: statusFg),
              )
                  : Icon(statusIcon, color: statusFg, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusTitle,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: statusFg)),
                    if (hasLoc && !_locationLoading) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: _T.sub,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _LocButton(
                icon: Icons.refresh_rounded,
                label: 'Refresh',
                onTap: _fetchCurrentLocation,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LocButton(
                icon: Icons.map_outlined,
                label: 'View Map',
                onTap: hasLoc ? _openMap : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _locationConfirmed
                // Fix: const when no runtime values needed
                    ? const _ConfirmBtn(done: true, label: 'Confirmed')
                    : _ConfirmBtn(
                  done: false,
                  label: 'Confirm',
                  onTap: hasLoc
                      ? () {
                    setState(() => _locationConfirmed = true);
                    HapticFeedback.mediumImpact();
                    _toast('Location confirmed!',
                        type: _ToastType.success);
                  }
                      : null,
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ─── DESCRIPTION CARD ─────────────────────────────────────
  Widget _buildDescCard() {
    return _Card(
      child: TextField(
        controller: _descCtrl,
        focusNode: _descFocus,
        maxLines: 6,
        maxLength: 500,
        style: const TextStyle(fontSize: 14.5, color: _T.tx, height: 1.65),
        decoration: InputDecoration(
          hintText: 'Describe the issue clearly…\n\n'
              '• What is the problem?\n'
              '• How long has it been there?\n'
              '• Any potential hazards?',
          hintStyle:
          TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.6),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          counterStyle: const TextStyle(color: _T.sub, fontSize: 12),
        ),
      ),
    );
  }

  // ─── BOTTOM BAR ───────────────────────────────────────────
  Widget _buildBottomBar(double safeBottom) {
    return Container(
      // Fix: .withValues(alpha:) replaces deprecated .withOpacity()
      decoration: BoxDecoration(
        color: _T.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 14, 16, safeBottom + 14),
      child: SafeArea(
        child: ScaleTransition(
          scale: _submitPulse,
          child: FilledButton(
            onPressed: _loading ? null : _onSubmitTap,
            style: FilledButton.styleFrom(
              backgroundColor: _T.g800,
              disabledBackgroundColor: const Color(0xFFB0BEC5),
              minimumSize: const Size(double.infinity, 58),
              // Fix: const shape
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(_T.rL),
              ),
              elevation: 0,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _loading
                  ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Submit Complaint',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
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

// ─────────────────────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String   title;
  final String   subtitle;

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 42, height: 42,
      decoration: const BoxDecoration(
        color: _T.g50,
        borderRadius: BorderRadius.all(_T.rM),
      ),
      child: Icon(icon, color: _T.g800, size: 20),
    ),
    const SizedBox(width: 14),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _T.tx)),
          const SizedBox(height: 1),
          Text(subtitle,
              style: const TextStyle(fontSize: 12.5, color: _T.sub)),
        ],
      ),
    ),
  ]);
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _T.card,
      borderRadius: const BorderRadius.all(_T.rXL),
      boxShadow: _T.cardShadow,
      border: Border.all(color: _T.brd),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({
    required this.canAdd,
    required this.label,
    this.onTap,
  });

  final bool          canAdd;
  final String        label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: canAdd ? _T.g50 : const Color(0xFFF5F5F5),
        borderRadius: const BorderRadius.all(_T.rL),
        border: Border.all(
          // Fix: .withValues(alpha:) replaces deprecated .withOpacity()
          color: canAdd
              ? _T.g800.withValues(alpha: 0.28)
              : const Color(0xFFE0E0E0),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            canAdd
                ? Icons.add_photo_alternate_outlined
                : Icons.check_circle_outline_rounded,
            color: canAdd ? _T.g800 : Colors.grey[500],
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: canAdd ? _T.g800 : Colors.grey[500],
            ),
          ),
        ],
      ),
    ),
  );
}

class _LocButton extends StatelessWidget {
  const _LocButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData      icon;
  final String        label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? _T.bg : const Color(0xFFF5F5F5),
          borderRadius: const BorderRadius.all(_T.rM),
        ),
        child: Column(children: [
          Icon(icon, color: enabled ? _T.g800 : Colors.grey[400], size: 21),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: enabled ? _T.tx : Colors.grey[400],
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _ConfirmBtn extends StatelessWidget {
  const _ConfirmBtn({
    required this.done,
    required this.label,
    this.onTap,
  });

  final bool          done;
  final String        label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFFB0BEC5)
            : (onTap != null ? _T.g800 : const Color(0xFFCFD8DC)),
        borderRadius: const BorderRadius.all(_T.rM),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            done ? Icons.check_rounded : Icons.check_circle_outline_rounded,
            size: 17,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  BOTTOM SHEETS
// ─────────────────────────────────────────────────────────────

class _AnonSheet extends StatelessWidget {
  const _AnonSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.all(_T.rXL),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
                color: _T.g50, shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined, size: 32, color: _T.g800),
          ),
          const SizedBox(height: 18),
          const Text('Privacy Options',
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: _T.tx)),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Your identity stays confidential. Authorities and the public '
                  'will NOT see your personal details.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: _T.sub, height: 1.55),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: _T.g800, width: 1.5),
                    // Fix: const shape
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(_T.rL),
                    ),
                  ),
                  child: const Text('With Name',
                      style: TextStyle(
                          color: _T.g800,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: _T.g800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    // Fix: const shape
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(_T.rL),
                    ),
                  ),
                  child: const Text('Anonymous',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ]),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
          color: _T.card, borderRadius: BorderRadius.all(_T.rXL)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Add Photo',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _T.tx)),
          const SizedBox(height: 14),
          // Fix: const _PickerTile for camera (all values are compile-time const)
          _PickerTile(
            icon: Icons.camera_alt_rounded,
            iconBg: _T.g50,
            iconColor: _T.g800,
            title: 'Take Photo',
            subtitle: 'Use your camera',
            onTap: onCamera,
          ),
          Divider(height: 1, indent: 72, color: Colors.grey[100]),
          _PickerTile(
            icon: Icons.photo_library_outlined,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1565C0),
            title: 'Choose from Gallery',
            subtitle: 'Select an existing photo',
            onTap: onGallery,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData      icon;
  final Color         iconBg;
  final Color         iconColor;
  final String        title;
  final String        subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    leading: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
          color: iconBg,
          borderRadius: const BorderRadius.all(_T.rM)),
      child: Icon(icon, color: iconColor, size: 24),
    ),
    title: Text(title,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.5,
            color: _T.tx)),
    subtitle: Text(subtitle,
        style: const TextStyle(fontSize: 13, color: _T.sub)),
    trailing:
    Icon(Icons.chevron_right_rounded, color: Colors.grey[350]),
    onTap: onTap,
  );
}