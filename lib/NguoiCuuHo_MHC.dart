import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({Key? key}) : super(key: key);

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  GoogleMapController? _mapController;

  // Tọa độ trung tâm mặc định (Ví dụ: Quận 7, TP.HCM)
  static const LatLng _centerPosition = LatLng(10.732660, 106.702798);

  bool isOnline = true;
  String selectedRadius = '3.0 km (Chuẩn)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Bác sĩ & Trạng thái
            _buildTopProfileHeader(),

            // 2. Khu vực Google Map
            Expanded(
              child: Stack(
                children: [
                  // --- HIỂN THỊ GOOGLE MAP ---
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _centerPosition,
                      zoom: 14.0,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    // Vẽ vòng tròn bán kính 3.0 km tượng trưng
                    circles: {
                      Circle(
                        circleId: const CircleId('scan_radius'),
                        center: _centerPosition,
                        radius: 500, // 500m = 0.5 km
                        fillColor: const Color.fromARGB(
                          255,
                          60,
                          20,
                          221,
                        ).withOpacity(0.12),
                        strokeColor: const Color.fromARGB(
                          255,
                          57,
                          54,
                          244,
                        ).withOpacity(0.5),
                        strokeWidth: 2,
                      ),
                    },
                  ),

                  // Badge Bán kính quét góc trên bên trái
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
                        children: const [
                          Icon(Icons.circle, color: Colors.red, size: 10),
                          SizedBox(width: 6),
                          Text(
                            'Bán kính quét: 3.0 km (Q.7)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Các nút điều khiển bản đồ bên phải
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
                          onTap: () {
                            // Quay lại vị trí trung tâm
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(_centerPosition, 14.0),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Bottom Panel (Bảng thông tin bên dưới)
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  // Header thông tin Bác sĩ
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

  // Nút tròn công cụ trên bản đồ
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

  // Bảng phía dưới
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
          // Thẻ Trạng thái Quét
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

          // 3 Cột Thống kê
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

          // Cấu hình Bán kính
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
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
                'Bán kính: 3 km',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Các Nút Bán kính (1.0 km, 3.0 km, 5.0 km)
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
        onTap: () => setState(() => selectedRadius = text),
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
