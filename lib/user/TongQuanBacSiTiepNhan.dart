import 'package:flutter/material.dart';

void main() {
  runApp(const RescuerOverviewApp());
}

class RescuerOverviewApp extends StatelessWidget {
  const RescuerOverviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFA7B1C2),
        fontFamily: 'Roboto',
      ),
      home: const RescuerOverviewScreen(),
    );
  }
}

class RescuerModel {
  final int id;
  final String name;
  final String roleTag;
  final String time;
  final String distance;

  RescuerModel({
    required this.id,
    required this.name,
    required this.roleTag,
    required this.time,
    required this.distance,
  });
}

class RescuerOverviewScreen extends StatefulWidget {
  const RescuerOverviewScreen({super.key});

  @override
  State<RescuerOverviewScreen> createState() => _RescuerOverviewScreenState();
}

class _RescuerOverviewScreenState extends State<RescuerOverviewScreen> {
  final List<RescuerModel> rescuers = [
    RescuerModel(
      id: 1,
      name: 'BS. Mai A',
      roleTag: '115 cơ động',
      time: '3–5 phút',
      distance: '800m',
    ),
    RescuerModel(
      id: 2,
      name: 'BS. CKI. Tuấn',
      roleTag: 'BV Chợ Rẫy',
      time: '7–10 phút',
      distance: '1.5 km',
    ),
    RescuerModel(
      id: 3,
      name: 'KTV. Hoàng',
      roleTag: 'BV Bạch Mai',
      time: '12–15 phút',
      distance: '2.8 km',
    ),
    RescuerModel(
      id: 4,
      name: 'BS. Nam',
      roleTag: 'Chấn thương',
      time: '16–20 phút',
      distance: '3.4 km',
    ),
    RescuerModel(
      id: 5,
      name: 'ĐĐ. Lê Thu',
      roleTag: 'Cấp cứu',
      time: '22–25 phút',
      distance: '4.5 km',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 2),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 1. LỚP BẢN ĐỒ VỚI CÁC MARKER CỨU HỘ
              const Positioned.fill(child: RescuerMapMock()),

              // 2. CÁC NÚT ĐIỀU HƯỚNG TRÊN BẢN ĐỒ (TOP & RIGHT OVERLAY)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Nút Back
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black87,
                                size: 20,
                              ),
                              onPressed: () {},
                            ),
                          ),
                          const Spacer(),

                          // Badge 5/5 người đang đến
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6),
                              ],
                            ),
                            child: const Row(
                              children: [
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor: Color(0xFF10B981),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '5/5 người đang đến',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Nút SOS khẩn cấp
                          CircleAvatar(
                            backgroundColor: const Color(0xFFFDE8E8),
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(
                                Icons.phone_in_talk,
                                color: Color(0xFFE53E3E),
                                size: 18,
                              ),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Nút Share
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(
                                Icons.share,
                                color: Colors.black87,
                                size: 18,
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Dòng thông báo GPS nạn nhân
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C5C4D),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cell_tower,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'GPS nạn nhân: Chính xác cao (±2m)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cụm nút điều khiển map bên phải (Định vị, Zoom in/out, Layer)
              Positioned(
                right: 16,
                top: 130,
                child: Column(
                  children: [
                    _buildMapIconButton(Icons.my_location),
                    const SizedBox(height: 8),
                    _buildMapIconButton(Icons.add),
                    const SizedBox(height: 2),
                    _buildMapIconButton(Icons.remove),
                    const SizedBox(height: 8),
                    _buildMapIconButton(Icons.layers_outlined),
                  ],
                ),
              ),

              // 3. THẺ DANH SÁCH "NGƯỜI CỨU HỘ TIẾP NHẬN" (BOTTOM PANEL)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Thanh kéo gạch xám phía trên
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Tiêu đề danh sách
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Người cứu hộ tiếp nhận',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2F7F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '5/5 người',
                              style: TextStyle(
                                color: Color(0xFF0C5C4D),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // List các người cứu hộ
                      Column(
                        children: rescuers
                            .map((res) => _buildRescuerItem(res))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget xây dựng từng item trong danh sách cứu hộ
  Widget _buildRescuerItem(RescuerModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Số thứ tự (1, 2, 3...)
          SizedBox(
            width: 20,
            child: Text(
              '${item.id}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Avatar hình tròn
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 10),

          // Thông tin Bác sĩ / KTV
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• ${item.roleTag}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const Text(
                      '  •  ',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    Text(
                      item.distance,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nút "Đường đi"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.alt_route, size: 14, color: Colors.black87),
                SizedBox(width: 4),
                Text(
                  'Đường đi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Nút gọi thoại đen tròn
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF0F172A),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.phone, size: 14, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  // Widget tạo các nút nhỏ góc phải map
  Widget _buildMapIconButton(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Icon(icon, size: 16, color: Colors.black87),
    );
  }
}

/// Giả lập lớp Bản đồ cùng 5 Marker cứu hộ và Marker SOS trung tâm
class RescuerMapMock extends StatelessWidget {
  const RescuerMapMock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFECEFF1),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nền các ô khối phố phường giả lập
          CustomPaint(size: Size.infinite, painter: CityGridPainter()),

          // Marker Trung Tâm: SOS "Vị trí của bạn"
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red[100]!, width: 4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8),
                  ],
                ),
                child: const Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      'Vị trí của bạn',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Các Marker người cứu hộ xunh quanh (1 - 5)[cite: 8]
          _buildMapRescuerMarker(top: 220, left: 120, id: 1),
          _buildMapRescuerMarker(top: 200, right: 110, id: 2),
          _buildMapRescuerMarker(top: 280, right: 50, id: 3),
          _buildMapRescuerMarker(bottom: 380, right: 100, id: 4),
          _buildMapRescuerMarker(bottom: 380, left: 80, id: 5),
        ],
      ),
    );
  }

  Widget _buildMapRescuerMarker({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required int id,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF0C5C4D),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.grey, size: 22),
            ),
          ),
          Positioned(
            top: -2,
            left: -2,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: const Color(0xFF0C5C4D),
              child: Text(
                '$id',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter vẽ nền lưới giao thông phố xá[cite: 8]
class CityGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blockPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    // Vẽ một số khối nhà/phố đại diện
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 80, 100, 120),
        const Radius.circular(8),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(140, 80, 120, 100),
        const Radius.circular(8),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(280, 80, 100, 150),
        const Radius.circular(8),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 220, 120, 100),
        const Radius.circular(8),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(160, 200, 100, 140),
        const Radius.circular(8),
      ),
      blockPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
