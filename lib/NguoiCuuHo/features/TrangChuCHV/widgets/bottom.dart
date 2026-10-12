import 'dart:async';

import 'package:cuhokhancap/core/color/Color_CHV.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuhokhancap/NguoiCuuHo/features/TrangChuCHV/controllers/trang_chu_controller.dart';

class TrangChuBottomPanel extends StatelessWidget {
  final String selectedRadius;
  final ValueChanged<String> onRadiusSelected;
  final bool isOnline;
  final Timer? timer;
  final int? soLuongCaTiepNhan;

  const TrangChuBottomPanel({
    super.key,
    required this.selectedRadius,
    required this.onRadiusSelected,
    required this.isOnline,
    required this.timer,
    required this.soLuongCaTiepNhan,
  });

  @override
  Widget build(BuildContext context) {
    // Lắng nghe Controller tự động cập nhật từng giây
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isOnline
                              ? ColorCHV.tiep_nhan_yeu_cau
                              : ColorCHV.ngung_tiep_nhan_yeu_cau,
                        ),
                      ),
                      Text(
                        isOnline
                            ? 'Đang quét tín hiệu cứu nạn...'
                            : 'Ngừng quét tín hiệu cứu nạn...',
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
                  isOnline
                      ? ColorCHV.tiep_nhan_yeu_cau
                      : ColorCHV.ngung_tiep_nhan_yeu_cau,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  Icons.medical_services_outlined,
                  'Hôm nay',
                  isOnline ? '${provider.soLuongCaTiepNhan} ca' : '0 ca',
                  isOnline
                      ? ColorCHV.tiep_nhan_yeu_cau
                      : ColorCHV.ngung_tiep_nhan_yeu_cau,
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
                style: TextStyle(
                  fontSize: 12,
                  color: isOnline
                      ? ColorCHV.tiep_nhan_yeu_cau
                      : ColorCHV.ngung_tiep_nhan_yeu_cau,
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
        onTap: () => onRadiusSelected(text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isOnline
                      ? ColorCHV.tiep_nhan_yeu_cau
                      : ColorCHV.ngung_tiep_nhan_yeu_cau)
                : const Color(0xFFF3F4F6),
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
