import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/controllers/trang_chu_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Không còn state riêng: tab hiện tại do widget cha quản lý (currentTabIndex).
class TrangChuBottomPanel extends StatelessWidget {
  final bool isOnline;
  final int soLuongCaHoanThanh;
  final int currentTabIndex;
  final Function(int index)? onTabSelected;

  /// Chấm vàng trên tab DỤNG CỤ - chỉ bật khi thật sự có cảnh báo.
  final bool showToolsBadge;

  const TrangChuBottomPanel({
    super.key,
    required this.isOnline,
    required this.soLuongCaHoanThanh,
    this.currentTabIndex = 0,
    this.onTabSelected,
    this.showToolsBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currentTabIndex == 0) _buildStatsRow(context),

        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0B132B),
            border: Border(top: BorderSide(color: Color(0xFF1C2541))),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.radar_rounded,
                label: 'TRỰC CHIẾN',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.history_rounded,
                label: 'LỊCH SỬ',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.emoji_events,
                label: 'THÀNH TÍCH',
                hasBadge: showToolsBadge,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.leaderboard,
                label: 'XẾP HẠNG',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.shield_outlined,
                label: 'HỒ SƠ',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final controller = context.read<TrangChuController>();
    // Chỉ rebuild phần cần thiết, không rebuild cả thanh điều hướng mỗi giây
    final double? accuracy = context.select<TrangChuController, double?>(
      (c) => c.gpsAccuracy,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: controller.onlineSecondsNotifier,
              builder: (_, __, ___) => _buildStatCard(
                Icons.access_time_rounded,
                'CA TRỰC',
                isOnline ? controller.formattedOnlineTime : 'Nghỉ trực',
                const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildStatCard(
              Icons.medical_services_rounded,
              'ĐÃ CỨU HỘ',
              '$soLuongCaHoanThanh ca',
              const Color(0xFF059669),
              iconColor: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildStatCard(
              Icons.cell_wifi_rounded,
              'SAI LỆCH ĐỊNH VỊ',
              // 🟢 Dữ liệu thật từ GPS thay cho chuỗi cứng '±1m'
              accuracy == null ? '--' : '±${accuracy.toStringAsFixed(0)}m',
              const Color(0xFF0284C7),
              iconColor: const Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    Color valueColor, {
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: iconColor ?? Colors.grey[600]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool hasBadge = false,
  }) {
    final bool isSelected = currentTabIndex == index;
    const Color activeColor = Colors.white;
    const Color inactiveColor = Color(0xFF94A3B8);

    // Expanded + padding: vùng chạm lớn, chia đều 5 tab
    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected?.call(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 20,
                  ),
                  if (hasBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
