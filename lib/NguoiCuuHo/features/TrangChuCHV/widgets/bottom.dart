import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/controllers/trang_chu_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TrangChuBottomPanel extends StatelessWidget {
  final bool isOnline;
  final int? soLuongCaTiepNhan;

  const TrangChuBottomPanel({
    super.key,
    required this.isOnline,
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
