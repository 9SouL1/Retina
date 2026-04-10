import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/database_service.dart';
import 'history.dart';

class Shift extends StatefulWidget {
  const Shift({super.key});

  @override
  State<Shift> createState() => _ShiftState();
}

class _ShiftState extends State<Shift> {
  String _currentTime = "";
  String _currentLocation = "Getting location...";
  late Timer _timer;
  String _selectedShiftType = "CLOCK IN";
  final String _selectedCompany = "AppCase Inc.";
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<Color> brandGradient = const [
    Color(0xFF5A7AFF),
    Color(0xFFC778FD),
    Color(0xFFF2709C),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
  }

  Future<void> _loadCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = "Location services disabled";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = "Location permission denied";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = "Location permission permanently denied";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];
      setState(() {
        _currentLocation = "${place.name ?? ''}, ${place.locality}, ${place.administrativeArea}";
      });
    } catch (e) {
      setState(() {
        _currentLocation = "Unable to get location";
      });
    }
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('h:mm a').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _capturedImage = File(photo.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photo: $e')),
      );
    }
  }

  Future<void> _submitAttendance() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture a photo first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'attendance_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = '${dir.path}/$fileName';
      await _capturedImage!.copy(imagePath);

      await DatabaseService.addRecord(
        imagePath: imagePath,
        company: _selectedCompany,
        shiftType: _selectedShiftType,
        location: _currentLocation,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const History()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving attendance: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "CLOCK IN",
                    style: TextStyle(
                      color: Color(0xFFC778FD),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    if (_capturedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_capturedImage!, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.camera_alt, color: Colors.white54, size: 80),
                      ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _capturePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(255, 255, 255, 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildBorderedField(Icons.location_on, _currentLocation)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildBorderedField(Icons.business, _selectedCompany)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildBorderedField(Icons.access_time, _currentTime)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildDropdownField()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatusField(),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Container(
                width: 220,
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [brandGradient[0], brandGradient[2]]),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "SUBMIT",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorderedField(IconData icon, String text) {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedShiftType,
          dropdownColor: Colors.black,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items: ["CLOCK IN", "CLOCK OUT"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedShiftType = val!),
        ),
      ),
    );
  }

  Widget _buildStatusField() {
    final status = _capturedImage != null ? "READY TO SUBMIT" : "CAPTURE PHOTO";
    return Container(
      height: 35,
      width: 180,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        "STATUS: $status",
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
