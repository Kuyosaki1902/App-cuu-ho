import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/TrangChu_NCH.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rescue_process_controller.dart';

class Step4CompletedFullView extends StatelessWidget {
  final String currentUserId;
  final String maYeuCauCuuHo;

  const Step4CompletedFullView({
    super.key,
    required this.currentUserId,
    required this.maYeuCauCuuHo,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RescueProcessController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // 📄 THẺ CHÍNH: PHIẾU BÀN GIAO KỸ THUẬT SỐ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE52525),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PHIẾU BÀN GIAO KỸ THUẬT SỐ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            '#$maYeuCauCuuHo',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '09:40\nSA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Thông tin bệnh nhân
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.victimName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Text(
                                '(Nạn nhân khẩn cấp)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFFCDD2),
                              ),
                            ),
                            child: const Text(
                              'Cấp 2 - Vết thương nặng',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE52525),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Color(0xFFE52525),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              controller.victimAddress,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tổng thời gian & Sinh hiệu
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tổng thời gian',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: Color(0xFF059669),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.formattedRescueTime,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sinh hiệu tiếp nhận',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                                Icon(
                                  Icons.favorite_outline,
                                  size: 14,
                                  color: Color(0xFF2563EB),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ổn định',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 🔴 NÚT SẴN SÀNG CA MỚI (CẬP NHẬT nhanCaCuuHo = false TẠI ĐÂY)
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE52525).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE52525),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                // 1. Cập nhật nhanCaCuuHo = false lên Firestore để giải phóng trạng thái trực
                await controller.releaseRescueDuty(currentUserId);

                // 🟢 ĐÃ XÓA controller.resetToNewCase(); Ở ĐÂY ĐỂ TRÁNH KÍCH HOẠT REBUILD MÀN HÌNH CŨ

                if (context.mounted) {
                  // 2. XÓA SẠCH STACK VÀ ĐƯA VỀ TRANG CHỦ
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          Trangchunguoicuuho(currentUserId: currentUserId),
                    ),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.near_me, color: Colors.white, size: 18),
              label: const Text(
                'SẴN SÀNG CA MỚI',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
