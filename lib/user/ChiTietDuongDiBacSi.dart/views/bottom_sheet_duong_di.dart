// lib/user/ChiTietDuongDi/views/bottom_sheet_duong_di.dart
import 'dart:convert';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/views/rescuer_overview_components.dart';
import 'package:flutter/material.dart';
import '../controllers/chi_tiet_duong_di_controller.dart';
import 'package:cuhokhancap/user/ChatVoiBacSi/ChatVoiBacSi.dart';

class ChiTietDuongDiBottomSheet extends StatefulWidget {
  final ChiTietDuongDiController controller;
  final String tenBacSi;
  final Color primaryColor;
  final bool isCollapsed;
  final ValueChanged<bool> onCollapseChanged;

  const ChiTietDuongDiBottomSheet({
    super.key,
    required this.controller,
    required this.tenBacSi,
    required this.primaryColor,
    required this.isCollapsed,
    required this.onCollapseChanged,
  });

  @override
  State<ChiTietDuongDiBottomSheet> createState() =>
      _ChiTietDuongDiBottomSheetState();
}

class _ChiTietDuongDiBottomSheetState extends State<ChiTietDuongDiBottomSheet> {
  double _dragDeltaY = 0.0;

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragDeltaY += details.delta.dy;
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragDeltaY > 25 || velocity > 250) {
      if (!widget.isCollapsed) {
        widget.onCollapseChanged(true);
      }
    } else if (_dragDeltaY < -25 || velocity < -250) {
      if (widget.isCollapsed) {
        widget.onCollapseChanged(false);
      }
    }
    _dragDeltaY = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final primaryColor = widget.primaryColor;
    final tenBacSi = widget.tenBacSi;
    final isCollapsed = widget.isCollapsed;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onCollapseChanged(!isCollapsed),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),

              if (!isCollapsed) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F7F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 3,
                            backgroundColor: Color(0xFF006A55),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            controller.trangthaiText,
                            style: const TextStyle(
                              color: Color(0xFF006A55),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'DỰ KIẾN TIẾP CẬN',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          controller.arrivalTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      controller.estimatedTime,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${controller.distanceText}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStepItem(
                          'Đã tiếp nhận',
                          Icons.check,
                          true,
                          primaryColor,
                        ),
                        _buildStepItem(
                          'Đang di chuyển',
                          Icons.directions_car,
                          controller.progressValue >= 0.5,
                          primaryColor,
                        ),
                        _buildStepItem(
                          'Đến nơi',
                          Icons.location_on,
                          controller.progressValue >= 1.0,
                          primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: controller.progressValue,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!isCollapsed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      FutureBuilder<String?>(
                        future: FirebaseService().getUserAvatarUrl(
                          controller.maNguoiCuuHo,
                        ),
                        builder: (context, snapshot) {
                          ImageProvider? avatarImg;
                          final raw = snapshot.data;
                          if (raw != null && raw.trim().isNotEmpty) {
                            final cleaned = raw.trim();
                            if (cleaned.startsWith('http://') ||
                                cleaned.startsWith('https://')) {
                              avatarImg = NetworkImage(cleaned);
                            } else {
                              try {
                                final base64Str = cleaned.contains(',')
                                    ? cleaned.split(',').last.trim()
                                    : cleaned;
                                avatarImg = MemoryImage(
                                  base64Decode(base64Str),
                                );
                              } catch (_) {}
                            }
                          }
                          return Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 23,
                              backgroundColor: primaryColor,
                              backgroundImage: avatarImg,
                              child: avatarImg == null
                                  ? Text(
                                      tenBacSi.isNotEmpty
                                          ? tenBacSi
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : 'BS',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenBacSi,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cấp cứu ngoại viện & Hỗ trợ y tế',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2F7F2),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatVoiBacSiScreen(
                                maPhongChat: controller.maYeuCau,
                                maNguoiCuuHo: controller.maNguoiCuuHo,
                                targetName: tenBacSi,
                                targetAvatar:
                                    'https://ui-avatars.com/api/?name=$tenBacSi&background=046450&color=fff',
                                victimLat: controller.victimLat,
                                victimLng: controller.victimLng,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.chat_bubble_outline,
                          color: primaryColor,
                          size: 18,
                        ),
                        label: Text(
                          'Nhắn tin',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          showEmergencyContactSheet(
                            context,
                            rescuerName: tenBacSi,
                            rescuerPhone: controller.soDienThoai,
                          );
                        },
                        icon: const Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Gọi cho bác sĩ',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(
    String title,
    IconData icon,
    bool isCompleted,
    Color primaryColor,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isCompleted ? primaryColor : Colors.grey.shade300,
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isCompleted ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }
}
