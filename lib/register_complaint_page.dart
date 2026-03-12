import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exif/exif.dart';

import 'config.dart';
import 'app_text.dart'; // ✅ ADDED

class RegisterComplaintPage extends StatefulWidget {
  const RegisterComplaintPage({super.key});

  @override
  State<RegisterComplaintPage> createState() => _RegisterComplaintPageState();
}

class _RegisterComplaintPageState extends State<RegisterComplaintPage> {
  final TextEditingController _descCtrl = TextEditingController();
  final List<File> _images = [];

  double? _lat;
  double? _lng;

  bool loading = false;
  bool locationLoading = false;
  bool locationConfirmed = false;

  final backendBase = AppConfig.backendBase;

  @override
  void initState() {
    super.initState();
    _resetLocation();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
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
        _snack("Location permission denied");
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
      _snack("Unable to fetch location");
    } finally {
      if (mounted) setState(() => locationLoading = false);
    }
  }

  /* ================= OPEN MAP ================= */

  Future<void> _openMap() async {
    if (_lat == null || _lng == null) return;

    final url =
        "https://www.google.com/maps/search/?api=1&query=$_lat,$_lng";

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    _snack("Adjust location in Google Maps, return and confirm");
  }

  /* ================= IMAGE PICK ================= */

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 5) {
      _snack("Maximum 5 images allowed");
      return;
    }

    final picker = ImagePicker();
    final XFile? picked =
    await picker.pickImage(source: source, imageQuality: 85);

    if (picked == null) return;

    final file = File(picked.path);
    setState(() => _images.add(file));

    if (source == ImageSource.gallery) {
      await _extractLocationFromImage(file);
    }
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
      }
    } catch (_) {}
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      if (_images.isEmpty) _resetLocation();
    });
  }

  /* ================= ANONYMOUS CONFIRM ================= */

  Future<void> _confirmAnonymousAndSubmit() async {
    if (loading) return;

    final bool? postAnonymous = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppText.t("anonymous")),
        content: const Text(
          "Your identity will remain confidential.\n\n"
              "Authorities and public users will NOT see your personal details.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("POST WITH NAME"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("POST ANONYMOUSLY"),
          ),
        ],
      ),
    );

    if (postAnonymous != null) {
      submitComplaint(isAnonymous: postAnonymous);
    }
  }

  /* ================= SUBMIT ================= */

  Future<void> submitComplaint({bool isAnonymous = false}) async {
    if (_images.isEmpty) {
      _snack("Please add at least one image");
      return;
    }

    if (_descCtrl.text.trim().length < 5) {
      _snack("Please enter a proper description");
      return;
    }

    if (_lat == null || _lng == null || !locationConfirmed) {
      _snack("Please confirm location");
      return;
    }

    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);

      if (token == null) {
        _snack("Session expired. Please login again.");
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
        try {
          final data = json.decode(response.body);
          if (data["duplicateWarning"] != null) {
            _snack(data["duplicateWarning"]);
          } else {
            _snack("Complaint submitted successfully");
          }
        } catch (_) {
          _snack("Complaint submitted successfully");
        }

        Navigator.pop(context);
      } else {
        try {
          final data = json.decode(response.body);
          final msg = data["message"] ?? "Submission failed. Try again.";
          _snack(msg);
        } catch (_) {
          _snack("Submission failed. Try again.");
        }
      }
    } catch (_) {
      _snack(AppText.t("networkError"));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    final hasLoc = _lat != null && _lng != null;

    return Scaffold(
      appBar: AppBar(title: Text(AppText.t("registerComplaint"))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: locationConfirmed
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationLoading
                              ? "Fetching location..."
                              : hasLoc
                              ? "Lat: $_lat , Lng: $_lng"
                              : "Location unavailable",
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: _openMap,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _fetchCurrentLocation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (hasLoc)
                    ElevatedButton(
                      onPressed: () {
                        setState(() => locationConfirmed = true);
                        _snack("Location confirmed");
                      },
                      child: const Text("CONFIRM LOCATION"),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _imageGrid(),
            const SizedBox(height: 20),
            _descField(),
            const SizedBox(height: 30),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _imageGrid() {
    return _card(
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ..._images.asMap().entries.map(
                (e) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    e.value,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(e.key),
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _addButton(),
        ],
      ),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: const Icon(Icons.add, size: 32, color: Colors.green),
      ),
    );
  }

  Widget _descField() {
    return _card(
      TextField(
        controller: _descCtrl,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: "Describe the issue clearly",
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : _confirmAnonymousAndSubmit,
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("SUBMIT COMPLAINT"),
      ),
    );
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        )
      ],
      color: Colors.white,
    ),
    child: child,
  );

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}