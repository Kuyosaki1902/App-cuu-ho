// lib/GiaoDienDangTimKiem/views/bottom_sheet_tim_kiem_ai.dart

import 'package:flutter/material.dart';
import '../controllers/tim_kiem_cuu_ho_controller.dart';

class BottomSheetTimKiemAIWidget extends StatelessWidget {
  final Color primaryColor;
  final TimKiemCuuHoController controller;

  const BottomSheetTimKiemAIWidget({
    super.key,
    required this.primaryColor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    int mucDoKhanCap = controller.yeuCauCuuHo?.mucDoKhanCap ?? 1;

    String trieuChungText = 'Chưa cập nhật triệu chứng';
    String moTaChiTietText = 'Chưa có mô tả chi tiết';

    final ghiChuData = controller.chiTietMoTa?.ghiChuText;
    if (ghiChuData is Map) {
      if (ghiChuData['trieuChung'] != null) {
        if (ghiChuData['trieuChung'] is List) {
          trieuChungText = (ghiChuData['trieuChung'] as List).join(', ');
        } else {
          trieuChungText = ghiChuData['trieuChung'].toString();
        }
      }
      if (ghiChuData['moTaChiTiet'] != null) {
        moTaChiTietText = ghiChuData['moTaChiTiet'].toString();
      }
    } else if (ghiChuData is String && ghiChuData.isNotEmpty) {
      trieuChungText = ghiChuData;
    }

    double currentRadiusKm =
        controller.scanRadii[controller.currentScanStep] / 1000;
    int rescuerCount = controller.rescuerList.length;
    bool isMaxScanReached =
        controller.currentScanStep == controller.scanRadii.length - 1;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 1. Tiêu đề + Bộ đếm thời gian nhảy từng giây bên phải
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.electric_bolt,
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PHỐI HỢP CẤP TỐC AI',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rescuerCount == 0
                            ? 'Đang tìm kiếm cứu hộ viên...'
                            : 'Đã tìm thấy $rescuerCount người cứu hộ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ⏱️ Bộ đếm thời gian bên phải
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.15)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.formattedElapsedTime,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                      const Text(
                        'Thời gian quét',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Khối Tình trạng bệnh nhân
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.thermostat, color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Tình trạng bệnh nhân',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ưu tiên $mucDoKhanCap',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trieuChungText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    moTaChiTietText,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Tiến trình Quét bán kính (Mở rộng liên tục đến 5km)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: rescuerCount > 0
                        ? const Color(0xFFE8F5E9)
                        : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rescuerCount > 0 ? Icons.check : Icons.search,
                    color: rescuerCount > 0 ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quét trong bán kính ${currentRadiusKm.toStringAsFixed(1)}km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        rescuerCount == 0
                            ? 'Đang mở rộng vùng quét tìm kiếm...'
                            : 'Đã tìm thấy $rescuerCount cứu hộ viên gần nhất',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  (rescuerCount >= 5 || isMaxScanReached)
                      ? 'Đã xong'
                      : 'Đang quét...',
                  style: TextStyle(
                    color: (rescuerCount >= 5 || isMaxScanReached)
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 🌟 4. MỤC "XÁC NHẬN NHẬN CA TRỰC TIẾP" (Đã khôi phục chuẩn thiết kế)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: rescuerCount > 0
                        ? Colors.blue.shade50
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_empty,
                    color: rescuerCount > 0 ? Colors.blue : Colors.grey,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xác nhận nhận ca trực tiếp',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        rescuerCount > 0
                            ? 'Đã gửi thông báo đến $rescuerCount cứu hộ viên'
                            : 'Chờ kết nối cứu hộ viên chấp nhận',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  rescuerCount > 0 ? 'Chờ xác nhận.' : 'Chờ ghép..',
                  style: TextStyle(
                    color: rescuerCount > 0
                        ? Colors.blue
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 5. Nút thao tác
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF3F8),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black87,
                      size: 18,
                    ),
                    label: const Text(
                      'Hủy tìm kiếm',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC81E1E),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.call, color: Colors.white, size: 18),
                    label: const Text(
                      'Cấp cứu 115',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
