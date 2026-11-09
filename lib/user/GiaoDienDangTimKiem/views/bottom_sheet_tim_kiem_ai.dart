// lib/GiaoDienDangTimKiem/views/bottom_sheet_tim_kiem_ai.dart

import 'package:flutter/material.dart';
import '../controllers/tim_kiem_cuu_ho_controller.dart';

class BottomSheetTimKiemAIWidget extends StatelessWidget {
  final Color primaryColor;
  final TimKiemCuuHoController controller;

  // 🌟 Nhận trạng thái và hàm trigger từ ngoài truyền vào
  final bool isExpanded;
  final Function(bool) onToggleExpanded;

  const BottomSheetTimKiemAIWidget({
    super.key,
    required this.primaryColor,
    required this.controller,
    required this.isExpanded,
    required this.onToggleExpanded,
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

    bool isManualSelect =
        controller.yeuCauCuuHo?.maLoaiYeuCau == 'loaiyeucau_choncuuhovien';
    int elapsed = controller.elapsedSeconds;

    String mainStatusText = '';
    String headerBadgeText = 'PHỐI HỢP CẤP TỐC AI';

    if (isManualSelect) {
      headerBadgeText = 'ĐIỀU PHỐI THỦ CÔNG';
      if (elapsed <= 60) {
        int targetCount = controller.manualSelectedCount > 0
            ? controller.manualSelectedCount
            : (controller.assignedRescuerIds.isNotEmpty
                  ? controller.assignedRescuerIds.length
                  : 1);
        mainStatusText = 'Đang chờ $targetCount cứu hộ viên tiếp nhận';
      } else if (elapsed > 60 && elapsed <= 120) {
        mainStatusText =
            'Đang tìm kiếm cứu hộ viên bổ sung. Đã tìm được $rescuerCount bác sĩ';
      } else {
        mainStatusText = 'Không tìm được, đang liên hệ admin';
      }
    } else {
      if (elapsed <= 60) {
        mainStatusText = rescuerCount == 0
            ? 'Đang tìm kiếm cứu hộ viên...'
            : 'Đã tìm thấy $rescuerCount người cứu hộ';
      } else {
        mainStatusText = 'Không tìm được, đang liên hệ admin';
      }
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        // Vuốt lên/xuống để đổi trạng thái
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0 && isExpanded) {
            onToggleExpanded(false); // Vuốt xuống -> Thu gọn
          } else if (details.primaryVelocity! < 0 && !isExpanded) {
            onToggleExpanded(true); // Vuốt lên -> Mở rộng
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
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
              // Thanh kéo (Nhấn để bật/tắt)
              GestureDetector(
                onTap: () {
                  onToggleExpanded(!isExpanded);
                },
                child: Container(
                  color: Colors.transparent, // Vùng bấm rộng hơn
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 1. Tiêu đề + Bộ đếm thời gian
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
                              headerBadgeText,
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
                          mainStatusText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ⏱️ Bộ đếm thời gian
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
                          controller.isLoading
                              ? '0s'
                              : controller.formattedElapsedTime,
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

              // 🌟 Ẩn/Hiện nội dung bên dưới khi thu gọn
              AnimatedCrossFade(
                firstChild: const SizedBox(height: 0), // Trạng thái đóng
                secondChild: Column(
                  children: [
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
                              const Icon(
                                Icons.thermostat,
                                color: Colors.red,
                                size: 18,
                              ),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Tiến trình Quét bán kính
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
                            color: rescuerCount > 0
                                ? Colors.green
                                : Colors.orange,
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

                    // 4. MỤC "XÁC NHẬN NHẬN CA TRỰC TIẾP"
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
                              const SizedBox(height: 2),
                              Text(
                                rescuerCount > 0
                                    ? 'Đã gửi thông báo đến $rescuerCount cứu hộ'
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
                  ],
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),

              const SizedBox(height: 20),

              // 5. Nút thao tác (Luôn hiển thị)
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
                      onPressed: () async {
                        if (controller.yeuCauCuuHo != null) {
                          await controller.cancelSearch(
                            controller.yeuCauCuuHo!.maYeuCau,
                          );
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
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
                      icon: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 18,
                      ),
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
      ),
    );
  }
}
