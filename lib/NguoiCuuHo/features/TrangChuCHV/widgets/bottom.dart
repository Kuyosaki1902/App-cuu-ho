import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/controllers/trang_chu_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TrangChuBottomPanel extends StatefulWidget {
  final bool isOnline;
  final int? soLuongCaTiepNhan;
  final int currentTabIndex; // 🟢 Tham số nhận vị trí Tab hiện tại
  final Function(int index)? onTabSelected;

  const TrangChuBottomPanel({
    super.key,
    required this.isOnline,
    required this.soLuongCaTiepNhan,
    this.currentTabIndex = 0,
    this.onTabSelected,
  });

  @override
  State<TrangChuBottomPanel> createState() => _TrangChuBottomPanelState();
}

class _TrangChuBottomPanelState extends State<TrangChuBottomPanel> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentTabIndex;
  }

  @override
  void didUpdateWidget(covariant TrangChuBottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTabIndex != widget.currentTabIndex) {
      setState(() {
        _selectedIndex = widget.currentTabIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrangChuController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🟢 CHỈ HIỂN THỊ THẺ THỐNG KÊ 3 Ô KHI Ở TAB 0 (TRỰC CHIẾN)
        if (widget.currentTabIndex == 0)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.access_time_rounded,
                    'CA TRỰC',
                    widget.isOnline
                        ? provider.formattedOnlineTime
                        : 'Nghỉ trực',
                    const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatCard(
                    Icons.medical_services_rounded,
                    'ĐÃ CỨU VIỆN',
                    '${widget.soLuongCaTiepNhan ?? 0} ca',
                    const Color(0xFF059669),
                    iconColor: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatCard(
                    Icons.cell_wifi_rounded,
                    'SAI LỆCH ĐỊNH VỊ',
                    '±1m',
                    const Color(0xFF0284C7),
                    iconColor: const Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),

        // Bottom Navigation Bar phong cách Dark Navy (Luôn giữ lại 5 nút cho tất cả các Tab)
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0B132B),
            border: Border(top: BorderSide(color: Color(0xFF1C2541))),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.ac_unit_rounded,
                label: 'TRỰC CHIẾN',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.history_rounded,
                label: 'LỊCH SỬ',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.medical_services_outlined,
                label: 'DỤNG CỤ',
                hasBadge: true,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.cell_tower_rounded,
                label: 'ĐIỀU PHỐI',
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
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
    bool isSelected = _selectedIndex == index;
    Color activeColor = Colors.white;
    Color inactiveColor = const Color(0xFF94A3B8);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (widget.onTabSelected != null) {
          widget.onTabSelected!(index);
        }
      },
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
    );
  }
}
