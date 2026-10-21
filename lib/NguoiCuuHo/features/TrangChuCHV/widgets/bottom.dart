import 'dart:async';
import 'package:cuhokhancap/core/color/Color_CHV.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/controllers/trang_chu_controller.dart';

class TrangChuBottomPanel extends StatelessWidget {
  final bool isOnline;
  final Timer? timer;
  final int? soLuongCaTiepNhan;

  const TrangChuBottomPanel({
    super.key,
    required this.isOnline,
    required this.timer,
    required this.soLuongCaTiepNhan,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrangChuController>();
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
                  child: Icon(
                    Icons.radar,
                    color: isOnline
                        ? ColorCHV.tiep_nhan_yeu_cau
                        : ColorCHV.ngung_tiep_nhan_yeu_cau,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline
                            ? 'Tiếp nhận yêu cầu'
                            : 'Ngưng tiếp nhận yêu cầu',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        isOnline
                            ? 'Đang sẵn sàng nhận ca trên toàn hệ thống...'
                            : 'Ngừng quét tín hiệu cứu nạn...',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
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
                  child: Text(
                    isOnline ? 'Chế độ chờ' : 'Chế độ\nnghỉ ngơi',
                    style: TextStyle(
                      color: isOnline
                          ? ColorCHV.tiep_nhan_yeu_cau
                          : ColorCHV.ngung_tiep_nhan_yeu_cau,
                      fontSize: 12,
                    ),
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
                  isOnline ? 'Trực ca' : 'Nghỉ ngơi',
                  isOnline ? provider.formattedOnlineTime : 'Offline',
                  Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  Icons.medical_services_outlined,
                  'Hôm nay',
                  isOnline ? '${provider.soLuongCaTiepNhan} ca' : '0 ca',
                  Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  Icons.speed,
                  'Tốc độ mạng',
                  'Ổn định',
                  Colors.black,
                ),
              ),
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
}
