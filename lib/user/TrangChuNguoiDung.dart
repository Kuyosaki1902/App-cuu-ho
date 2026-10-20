import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // THÊM THƯ VIỆN GPS
import 'MenuNguoiDung.dart'; 
import 'package:cuhokhancap/user/MoTaTinhTrang.dart'; 
import 'package:cuhokhancap/user/ChatVoiAI.dart';

class TrangChuNguoiDung extends StatefulWidget {
  final String maNguoiDung;
  const TrangChuNguoiDung({super.key, required this.maNguoiDung});

  @override
  State<TrangChuNguoiDung> createState() => _TrangChuNguoiDungState();
}

class _TrangChuNguoiDungState extends State<TrangChuNguoiDung> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;

  // Biến lưu tọa độ hiện tại
  LatLng _currentPosition = const LatLng(10.7725, 106.6980);
  double _currentRadius = 3000;

  @override
  void initState() {
    super.initState();
    // Tự động quét và xin quyền định vị ngay khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocationAndMove();
    });
  }

  // Hàm quét vị trí thực tế
  Future<void> _getCurrentLocationAndMove() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật định vị (GPS) trên điện thoại.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền định vị bị từ chối.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền định vị bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để cấp lại.')),
        );
      }
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    _recenterCamera();
  }

  // Hàm đưa Camera về đúng vị trí định vị mà không gọi lại GPS
  void _recenterCamera() {
    if (_mapController != null) {
      // Giữ nguyên thông số zoom của bạn
      double targetZoom = 12.5;
      if (_currentRadius == 1000) targetZoom = 13.5;
      if (_currentRadius == 5000) targetZoom = 11.5;

      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, targetZoom),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, 
      drawer: MenuNguoiDung(maNguoiDung: widget.maNguoiDung), 
      body: Stack(
        children: [
          GoogleMap(
            // Padding đẩy tâm bản đồ lên trên 400 pixel (né bảng Bottom Panel) và 100 pixel bên trên
            padding: const EdgeInsets.only(bottom: 400, top: 100),
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 13.5,
            ),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false, 
            myLocationEnabled: true, // Chấm xanh dương mặc định
            onMapCreated: (controller) {
              _mapController = controller;
            },
            // Đã xóa hoàn toàn khối markers (chấm đỏ) ở đây
            circles: {
              Circle(
                circleId: const CircleId('radius_circle'),
                center: _currentPosition, 
                radius: _currentRadius,
                fillColor: const Color(0xFF00695C).withValues(alpha: 0.15),
                strokeColor: const Color(0xFF00695C).withValues(alpha: 0.5),
                strokeWidth: 2,
              ),
            },
          ),

          // Thanh công cụ trên cùng
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircularButton(
                  icon: Icons.menu,
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildRadiusOption("1 km", 1000),
                      _buildRadiusOption("3 km", 3000),
                      _buildRadiusOption("5 km", 5000),
                    ],
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent, 
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30), 
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatVoiAIScreen()));
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Color(0xFF00695C), size: 16),
                            SizedBox(width: 4),
                            Text("Chat với AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 120,
            right: 16,
            child: Column(
              children: [
                // Nút chỉ dùng để di chuyển Camera về lại vị trí
                _buildCircularButton(
                  icon: Icons.center_focus_strong,
                  onTap: _recenterCamera, 
                ),
              ],
            ),
          ),

          // Khối ở dưới cùng
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.white, size: 30),
                        Text("SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFF00C853), size: 12),
                              SizedBox(width: 8),
                              Text("6 bác sĩ sẵn sàng nhận", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text("Tốc độ 8-15p", style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text("Trong bán kính quét 3km quanh vị trí hiện tại", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                              child: const VictimConditionSheet(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFF00695C), shape: BoxShape.circle),
                                child: const Icon(Icons.medical_services, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("MÔ TẢ VẤN ĐỀ", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Text("Hỗ trợ khẩn cấp", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const Text("Mô Tả", style: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text("TỰ ĐỘNG TÌM BÁC SĨ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text("Ghép bác sĩ gần nhất và đánh giá tốt nhất trong 60 giây", style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF5F6F8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu, color: Colors.black54, size: 18),
                            SizedBox(width: 8),
                            Text("Tự chọn bác sĩ từ danh sách", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user, color: Color(0xFF00C853), size: 16),
                          SizedBox(width: 4),
                          Text("Chứng chỉ hành nghề đã xác minh 100%", style: TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusOption(String text, double radiusValue) {
    bool isSelected = _currentRadius == radiusValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentRadius = radiusValue;
        });

        // Giữ nguyên thông số zoom của bạn
        double targetZoom = 13;
        if (radiusValue == 1000) targetZoom = 14.5;
        if (radiusValue == 5000) targetZoom = 12.5;

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, targetZoom),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF004D40) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }
}