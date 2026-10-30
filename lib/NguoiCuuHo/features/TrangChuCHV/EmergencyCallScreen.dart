import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/controllers/EmergencyCallListenerService.dart';
import 'package:flutter/material.dart';

class EmergencyCallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;
  final DocumentReference callDocRef;
  final EmergencyCallListenerService service;

  const EmergencyCallScreen({
    super.key,
    required this.callData,
    required this.callDocRef,
    required this.service,
  });

  @override
  State<EmergencyCallScreen> createState() => _EmergencyCallScreenState();
}

class _EmergencyCallScreenState extends State<EmergencyCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Hiệu ứng nhấp nháy cho icon SOS
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String message =
        widget.callData['noiDungDoc'] ??
        'Có cuộc gọi khẩn cấp SOS từ người thân!';

    return WillPopScope(
      onWillPop: () async =>
          false, // Chặn nút back để bắt buộc người dùng tương tác xử lý
      child: Scaffold(
        backgroundColor: const Color(0xFF991B1B), // Màu đỏ đậm cấp cứu
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Icon sóng khẩn cấp nhấp nháy
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.15).animate(_pulseController),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CẢNH BÁO KHẨN CẤP SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hệ thống đang phát thông báo tự động...',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 36),

                // Khung chứa nội dung thông báo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                const Spacer(),

                // Nút bấm xác nhận đã nghe / tắt cảnh báo
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    // 🟢 Sửa thành ElevatedButton đúng chuẩn
                    style: ElevatedButton.styleFrom(
                      // 🟢 Đưa styleFrom vào trong thuộc tính style
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF991B1B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      // 1. Tắt giọng đọc và cập nhật trạng thái đã nghe lên Firestore
                      await widget.service.updateCallStatusToFinished(
                        widget.callDocRef,
                      );

                      if (context.mounted) {
                        // 2. Đóng màn hình cuộc gọi
                        Navigator.pop(context);
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Đã hiểu / Tắt cảnh báo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
