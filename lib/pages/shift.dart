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
  String _currentLocation = "Requesting location permission...";
  late Timer _timer;
  StreamSubscription<Position>? _locationSubscription;
  bool _locationError = false;
  String _selectedShiftType = "CLOCK IN";
  final String _selectedCompany = "AppCase Inc.";
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _previewStatus;

  final List<Color> brandGradient = const [
    Color(0xFF5A7AFF),
    Color(0xFFC778FD),
    Color(0xFFF2709C),
  ];

  @override
  void initState() {
    super.initState();
    _updatePreviewStatus();
    _initializeLocation();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
        _updatePreviewStatus();
      }
    });
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = "Location services disabled";
          _locationError = true;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = "Location permission denied";
            _locationError = true;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = "Location permission permanently denied. Please enable in settings.";
          _locationError = true;
        });
        return;
      }

      _startLocationStream();
    } catch (e) {
      debugPrint('Shift _initializeLocation error: $e');
      setState(() {
        _currentLocation = "Unable to initialize location";
        _locationError = true;
      });
    }
  }

  void _startLocationStream() {
    setState(() {
      _locationError = false;
      _currentLocation = "Getting location...";
    });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        if (!mounted) return;
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty && mounted) {
            Placemark place = placemarks[0];
            setState(() {
              _currentLocation = "${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}".trim();
            });
          }
        } catch (e) {
          debugPrint('Shift geocoding error: $e');
          if (mounted) {
            setState(() {
              _currentLocation = "Unable to get address";
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _currentLocation = "Location stream error";
            _locationError = true;
          });
        }
      },
    );
  }

  Future<void> _retryLocation() async {
    _locationSubscription?.cancel();
    setState(() {
      _locationError = false;
    });
    await _initializeLocation();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('h:mm a').format(DateTime.now());
    });
  }

  void _updatePreviewStatus() {
    final now = DateTime.now();
    final hour = now.hour;
    if (_selectedShiftType == 'CLOCK IN') {
      _previewStatus = hour < 9 ? 'Present' : 'Late';
    } else {
      _previewStatus = hour > 18 ? 'Overtime' : (hour < 18 ? 'Early Out' : 'Regular');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer.cancel();
    _locationSubscription?.cancel();
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
      debugPrint('Shift capturePhoto error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photo')),
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
      debugPrint('Shift submitAttendance error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving attendance')),
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
                  Text(
                    _selectedShiftType,
                    style: const TextStyle(
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
                  if (_locationError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _retryLocation,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('Retry Location', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFC778FD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
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
          onChanged: (val) {
            setState(() => _selectedShiftType = val!);
            _updatePreviewStatus();
          },
        ),
      ),
    );
  }

  Widget _buildStatusField() {
    final readyStatus = _capturedImage != null ? 'READY' : 'CAPTURE PHOTO';
    final statusColor = _previewStatus == 'Present' || _previewStatus == 'Regular' 
      ? Colors.green 
      : (_previewStatus == 'Late' || _previewStatus == 'Early Out' ? Colors.orange : Colors.red);
    return Container(
      height: 35,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$readyStatus | $_previewStatus',
            style: TextStyle(
              color: statusColor,
              fontSize: 10, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
