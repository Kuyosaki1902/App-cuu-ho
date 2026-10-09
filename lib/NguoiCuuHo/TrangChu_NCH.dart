import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class Trangchunguoicuuho extends StatefulWidget {
  const Trangchunguoicuuho({Key? key}) : super(key: key);

  @override
  State<Trangchunguoicuuho> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<Trangchunguoicuuho> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Bỏ vị trí mặc định, khởi tạo ban đầu là null
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;

  bool isOnline = true;
  String selectedRadius = '3.0 km (Chuẩn)';

  @override
  void initState() {
    super.initState();
    _initLocationService();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // --- HÀM LẤY VỊ TRÍ THỰC TẾ TỪ GPS ---
  Future<void> _initLocationService() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isLoadingLocation = true);

    // 1. Kiểm tra bật GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng bật GPS/Vị trí trên thiết bị!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _isLoadingLocation = false);
      return;
    }

    // 2. Xin quyền truy cập vị trí
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối.')),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quyền vị trí bị từ chối vĩnh viễn trong Cài đặt.'),
          ),
        );
      }
      setState(() => _isLoadingLocation = false);
      return;
    }

    // 3. Lấy tọa độ GPS ban đầu từ thiết bị
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _updateLocationOnMap(LatLng(position.latitude, position.longitude));
    } catch (e) {
      debugPrint('Lỗi lấy vị trí: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }

    // 4. Lắng nghe vị trí di chuyển thực tế
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          _updateLocationOnMap(LatLng(position.latitude, position.longitude));
        });
  }

  void _updateLocationOnMap(LatLng newPos) {
    if (!mounted) return;
    setState(() {
      _currentPosition = newPos;
      _isLoadingLocation = false;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(newPos, _getZoomLevel()),
    );
  }

  double _getCircleRadiusInMeters() {
    if (selectedRadius.contains('1.0')) {
      return 1000.0;
    } else if (selectedRadius.contains('5.0')) {
      return 5000.0;
    } else {
      return 3000.0;
    }
  }

  double _getZoomLevel() {
    if (selectedRadius.contains('1.0')) {
      return 14.8;
    } else if (selectedRadius.contains('5.0')) {
      return 12.2;
    } else {
      return 13.2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bác sĩ
            _buildTopProfileHeader(),

            // 2. Khu vực Bản đồ
            Expanded(
              child: _currentPosition == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFFC80815),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isLoadingLocation
                                ? 'Đang định vị vị trí thực tế...'
                                : 'Chưa thể lấy vị trí. Vui lòng bật GPS và thử lại.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          if (!_isLoadingLocation)
                            TextButton.icon(
                              onPressed: _initLocationService,
                              icon: const Icon(
                                Icons.refresh,
                                color: Color(0xFFC80815),
                              ),
                              label: const Text(
                                'Thử lại',
                                style: TextStyle(color: Color(0xFFC80815)),
                              ),
                            ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        // --- GOOGLE MAP ---
                        GoogleMap(
                          key: ValueKey(
                            '${_currentPosition!.latitude}_${_currentPosition!.longitude}_$selectedRadius',
                          ),
                          initialCameraPosition: CameraPosition(
                            target: _currentPosition!,
                            zoom: _getZoomLevel(),
                          ),
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,

                          // Marker đúng vị trí thực tế
                          markers: {
                            Marker(
                              markerId: const MarkerId('current_user_location'),
                              position: _currentPosition!,
                              infoWindow: const InfoWindow(
                                title: 'Vị trí của bạn',
                                snippet: 'Đang trực cứu hộ',
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                          },

                          // Vòng tròn quét dựa trên tọa độ thực tế
                          circles: {
                            Circle(
                              circleId: const CircleId('scan_radius'),
                              center: _currentPosition!,
                              radius: _getCircleRadiusInMeters(),
                              fillColor: const Color(
                                0xFFC80815,
                              ).withOpacity(0.15),
                              strokeColor: const Color(
                                0xFFC80815,
                              ).withOpacity(0.6),
                              strokeWidth: 2,
                            ),
                          },
                        ),

                        // Badge Bán kính
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: Colors.red,
                                  size: 10,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Bán kính quét: ${selectedRadius.split(' ')[0]} km',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Nút thao tác nhanh
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Column(
                            children: [
                              _buildMapActionButton(
                                Icons.layers_outlined,
                                onTap: () {},
                              ),
                              const SizedBox(height: 8),
                              _buildMapActionButton(Icons.tune, onTap: () {}),
                              const SizedBox(height: 8),
                              _buildMapActionButton(
                                Icons.my_location,
                                iconColor: Colors.red,
                                onTap: _initLocationService,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            // 3. Bottom Panel
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  // Header Bác sĩ
  Widget _buildTopProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'BS. Trần Minh Tuấn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bác sĩ Hồi sức Cấp cứu Ngoại viện',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Color(0xFF16A34A), size: 10),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Đang sẵn sàng nhận ca',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Chia sẻ vị trí GPS thời gian thực',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOnline,
                  activeColor: const Color(0xFF047857),
                  onChanged: (val) => setState(() => isOnline = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionButton(
    IconData icon, {
    Color iconColor = Colors.black87,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.radar, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Chưa có yêu cầu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Đang quét tín hiệu cứu nạn...',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Chế độ chờ',
                    style: TextStyle(color: Color(0xFF059669), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.access_time,
                  'Trực ca',
                  '02h 15p',
                  Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  Icons.medical_services_outlined,
                  'Hôm nay',
                  '02 ca',
                  Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  Icons.support_agent,
                  'Tổng đài',
                  'Ổn định',
                  const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.near_me_outlined, size: 18, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'THIẾT LẬP PHẠM VI TIẾP NHẬN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Text(
                'Bán kính: ${selectedRadius.split(' ')[0]} km',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRadiusOption('1.0 km'),
              const SizedBox(width: 8),
              _buildRadiusOption('3.0 km (Chuẩn)'),
              const SizedBox(width: 8),
              _buildRadiusOption('5.0 km'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    Color valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusOption(String text) {
    bool isSelected = selectedRadius == text;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedRadius = text;
          });
          if (_currentPosition != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_currentPosition!, _getZoomLevel()),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.red : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
