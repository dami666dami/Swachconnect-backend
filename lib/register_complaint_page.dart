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

class RegisterComplaintPage extends StatefulWidget {
  const RegisterComplaintPage({super.key});

  @override
  State<RegisterComplaintPage> createState() => _RegisterComplaintPageState();
}

class _RegisterComplaintPageState extends State<RegisterComplaintPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _descCtrl = TextEditingController();
  final FocusNode _descFocus = FocusNode();
  final List<File> _images = [];

  double? _lat;
  double? _lng;

  bool loading = false;
  bool locationLoading = false;
  bool locationConfirmed = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final backendBase = AppConfig.backendBase;

  // Theme colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFFE8F5E9);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color greyText = Color(0xFF757575);
  static const Color cardBg = Colors.white;
  static const Color scaffoldBg = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    _resetLocation();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _descFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _resetLocation() {
    setState(() {
      _lat = null;
      _lng = null;
      locationConfirmed = false;
    });
  }

  /* ================= AUTO LOCATION ================= */

  Future<void> _fetchCurrentLocation() async {
    setState(() => locationLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnackBar("Location permission denied", isError: true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        locationConfirmed = false;
      });
    } catch (_) {
      _showSnackBar("Unable to fetch location", isError: true);
    } finally {
      if (mounted) setState(() => locationLoading = false);
    }
  }

  /* ================= OPEN MAP ================= */

  Future<void> _openMap() async {
    if (_lat == null || _lng == null) return;

    final url = "[google.com](https://www.google.com/maps/search/?api=1&query=$_lat,$_lng)";

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    _showSnackBar("Adjust location in Maps, then return to confirm");
  }

  /* ================= IMAGE PICK ================= */

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 5) {
      _showSnackBar("Maximum 5 images allowed", isError: true);
      return;
    }

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked == null) return;

    final file = File(picked.path);
    setState(() => _images.add(file));

    if (source == ImageSource.gallery) {
      await _extractLocationFromImage(file);
    }

    HapticFeedback.lightImpact();
  }

  /* ================= IMAGE LOCATION (EXIF) ================= */

  Future<void> _extractLocationFromImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final tags = await readExifFromBytes(bytes);

      if (tags.containsKey('GPS GPSLatitude') &&
          tags.containsKey('GPS GPSLongitude')) {
        final latValues = tags['GPS GPSLatitude']!.values.toList();
        final lngValues = tags['GPS GPSLongitude']!.values.toList();

        final lat = latValues[0].toDouble() +
            latValues[1].toDouble() / 60 +
            latValues[2].toDouble() / 3600;

        final lng = lngValues[0].toDouble() +
            lngValues[1].toDouble() / 60 +
            lngValues[2].toDouble() / 3600;

        setState(() {
          _lat = lat;
          _lng = lng;
          locationConfirmed = false;
        });

        _showSnackBar("Location extracted from image");
      }
    } catch (_) {}
  }

  void _removeImage(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _images.removeAt(index);
      if (_images.isEmpty) _resetLocation();
    });
  }

  /* ================= ANONYMOUS CONFIRM ================= */

  Future<void> _confirmAnonymousAndSubmit() async {
    if (loading) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final bool? postAnonymous = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildAnonymousSheet(),
    );

    if (postAnonymous != null) {
      submitComplaint(isAnonymous: postAnonymous);
    }
  }

  Widget _buildAnonymousSheet() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 40,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Privacy Options",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Your identity will remain confidential. Authorities and public users will NOT see your personal details.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: greyText,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: primaryGreen, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "With Name",
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Anonymous",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  /* ================= SUBMIT ================= */

  Future<void> submitComplaint({bool isAnonymous = false}) async {
    if (_images.isEmpty) {
      _showSnackBar("Please add at least one image", isError: true);
      return;
    }

    if (_descCtrl.text.trim().length < 5) {
      _showSnackBar("Please enter a proper description", isError: true);
      _descFocus.requestFocus();
      return;
    }

    if (_lat == null || _lng == null || !locationConfirmed) {
      _showSnackBar("Please confirm location", isError: true);
      return;
    }

    setState(() => loading = true);
    HapticFeedback.mediumImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);

      if (token == null) {
        _showSnackBar("Session expired. Please login again.", isError: true);
        return;
      }

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$backendBase/api/complaints"),
      );

      request.headers["Authorization"] = "Bearer $token";

      request.fields.addAll({
        "description": _descCtrl.text.trim(),
        "lat": _lat!.toString(),
        "lng": _lng!.toString(),
        "isAnonymous": isAnonymous.toString(),
      });

      for (final img in _images) {
        request.files.add(
          await http.MultipartFile.fromPath("image", img.path),
        );
      }

      final streamedRes = await request.send();
      final response = await http.Response.fromStream(streamedRes);

      if (!mounted) return;

      if (response.statusCode == 201) {
        HapticFeedback.heavyImpact();
        try {
          final data = json.decode(response.body);
          if (data["duplicateWarning"] != null) {
            _showSnackBar(data["duplicateWarning"]);
          } else {
            _showSnackBar("Complaint submitted successfully!", isSuccess: true);
          }
        } catch (_) {
          _showSnackBar("Complaint submitted successfully!", isSuccess: true);
        }

        Navigator.pop(context);
      } else {
        try {
          final data = json.decode(response.body);
          final msg = data["message"] ?? "Submission failed. Try again.";
          _showSnackBar(msg, isError: true);
        } catch (_) {
          _showSnackBar("Submission failed. Try again.", isError: true);
        }
      }
    } catch (_) {
      _showSnackBar(AppText.t("networkError"), isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  icon: Icons.photo_library_outlined,
                  title: "Photos",
                  subtitle: "Add up to 5 images of the issue",
                ),
                const SizedBox(height: 12),
                _buildImageSection(),
                const SizedBox(height: 28),
                _buildSectionHeader(
                  icon: Icons.location_on_outlined,
                  title: "Location",
                  subtitle: "Verify the incident location",
                ),
                const SizedBox(height: 12),
                _buildLocationCard(),
                const SizedBox(height: 28),
                _buildSectionHeader(
                  icon: Icons.description_outlined,
                  title: "Description",
                  subtitle: "Describe the issue in detail",
                ),
                const SizedBox(height: 12),
                _buildDescriptionCard(),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: cardBg,
      surfaceTintColor: cardBg,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scaffoldBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t("registerComplaint"),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          Text(
            "Report an environmental issue",
            style: TextStyle(
              fontSize: 12,
              color: greyText,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryGreen, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: greyText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_images.isNotEmpty) ...[
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) => _buildImageTile(index),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildAddImageButton(),
        ],
      ),
    );
  }

  Widget _buildImageTile(int index) {
    return Stack(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _images[index],
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${index + 1}/${_images.length}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    final remaining = 5 - _images.length;
    final canAdd = remaining > 0;

    return GestureDetector(
      onTap: canAdd ? _showImagePicker : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: canAdd ? accentGreen : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canAdd ? primaryGreen.withOpacity(0.3) : Colors.grey[300]!,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canAdd ? Icons.add_photo_alternate_outlined : Icons.check_circle,
              color: canAdd ? primaryGreen : Colors.grey,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              canAdd ? "Add Photo ($remaining remaining)" : "Maximum images added",
              style: TextStyle(
                color: canAdd ? primaryGreen : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Add Photo",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 20),
            _buildPickerOption(
              icon: Icons.camera_alt_rounded,
              title: "Take Photo",
              subtitle: "Use your camera",
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            Divider(height: 1, indent: 70, color: Colors.grey[200]),
            _buildPickerOption(
              icon: Icons.photo_library_rounded,
              title: "Choose from Gallery",
              subtitle: "Select existing photo",
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: primaryGreen, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: darkText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: greyText,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildLocationCard() {
    final hasLoc = _lat != null && _lng != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: locationConfirmed
                  ? const Color(0xFFE8F5E9)
                  : hasLoc
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  locationConfirmed
                      ? Icons.check_circle
                      : hasLoc
                      ? Icons.info_outline
                      : Icons.error_outline,
                  color: locationConfirmed
                      ? primaryGreen
                      : hasLoc
                      ? Colors.orange[700]
                      : Colors.red[700],
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationLoading
                            ? "Fetching location..."
                            : locationConfirmed
                            ? "Location Confirmed"
                            : hasLoc
                            ? "Location Detected"
                            : "Location Unavailable",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: locationConfirmed
                              ? primaryGreen
                              : hasLoc
                              ? Colors.orange[800]
                              : Colors.red[700],
                        ),
                      ),
                      if (hasLoc && !locationLoading) ...[
                        const SizedBox(height: 2),
                        Text(
                          "${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: greyText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (locationLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryGreen,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildLocationAction(
                  icon: Icons.my_location,
                  label: "Refresh",
                  onTap: _fetchCurrentLocation,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLocationAction(
                  icon: Icons.map_outlined,
                  label: "View Map",
                  onTap: hasLoc ? _openMap : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton.icon(
                    onPressed: hasLoc && !locationConfirmed
                        ? () {
                      setState(() => locationConfirmed = true);
                      HapticFeedback.mediumImpact();
                      _showSnackBar("Location confirmed!", isSuccess: true);
                    }
                        : null,
                    icon: Icon(
                      locationConfirmed ? Icons.check : Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(locationConfirmed ? "Confirmed" : "Confirm"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: locationConfirmed ? Colors.grey[300] : primaryGreen,
                      foregroundColor: locationConfirmed ? greyText : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? scaffoldBg : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: enabled ? primaryGreen : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? darkText : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _descCtrl,
            focusNode: _descFocus,
            maxLines: 5,
            maxLength: 500,
            style: const TextStyle(
              fontSize: 15,
              color: darkText,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: "Describe the issue clearly...\n\nInclude details like:\n• What is the problem?\n• How long has it been there?\n• Any potential hazards?",
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.6,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              counterStyle: TextStyle(
                color: greyText,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isValid = _images.isNotEmpty &&
        _descCtrl.text.trim().length >= 5 &&
        locationConfirmed;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: loading ? null : _confirmAnonymousAndSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            disabledBackgroundColor: Colors.grey[300],
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: loading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.send_rounded, size: 20),
                SizedBox(width: 10),
                Text(
                  "Submit Complaint",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

  void _showSnackBar(String msg, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : isSuccess
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.red[600]
            : isSuccess
            ? primaryGreen
            : Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }
}
