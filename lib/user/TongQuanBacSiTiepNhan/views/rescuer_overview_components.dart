// lib/user/TongQuanBacSiTiepNhan/views/rescuer_overview_components.dart
import 'dart:convert';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/ChatVoiAI.dart';
import 'package:cuhokhancap/user/ChatVoiBacSi/ChatVoiBacSi.dart';
import 'package:cuhokhancap/user/ThongTInHoanThanhCuuHo/HoanThanhCuuHo.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/Models/tracking_rescuer_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// 0. HÀM MỞ BÀN PHÍM GỌI & MODAL LIÊN HỆ KHẨN CẤP DÙNG CHUNG CHO CẢ 2 MÀN
Future<void> launchPhoneDialer(BuildContext context, String rawPhone) async {
  final cleaned = rawPhone.replaceAll(RegExp(r'[\s\.\-\(\)]'), '').trim();
  if (cleaned.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cứu hộ viên chưa cập nhật số điện thoại.'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  final uri = Uri(scheme: 'tel', path: cleaned);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở ứng dụng gọi cho số $cleaned.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở ứng dụng gọi cho số $cleaned.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

void showEmergencyContactSheet(
  BuildContext context, {
  required String rescuerName,
  required String rescuerPhone,
}) {
  final cleanRescuerPhone = rescuerPhone.trim();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Liên hệ khẩn cấp',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Card 1: Gọi cho cứu hộ viên
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(ctx);
                  launchPhoneDialer(context, cleanRescuerPhone);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rescuerName.isNotEmpty
                                  ? rescuerName
                                  : 'Cứu hộ viên',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              cleanRescuerPhone.isNotEmpty
                                  ? 'Cứu hộ viên hỗ trợ • Nhấn để gọi'
                                  : 'Chưa cập nhật số điện thoại',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (cleanRescuerPhone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                cleanRescuerPhone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cleanRescuerPhone.isNotEmpty
                            ? const Color(0xFF0B7A4B)
                            : Colors.grey.shade400,
                        child: const Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 16),

              // Card 2: Gọi tổng đài cấp cứu 115
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(ctx);
                  launchPhoneDialer(context, '115');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng đài cấp cứu 115',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Điều phối viên hỗ trợ ca trực • Nhấn để gọi',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '115',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFF0B7A4B),
                        child: Icon(Icons.phone, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// 1. THANH ĐIỀU HƯỚNG TRÊN CÙNG (TOP NAV BAR)
// 1. THANH ĐIỀU HƯỚNG TRÊN CÙNG (TOP NAV BAR)
class RescuerTopNavBar extends StatelessWidget {
  final int rescuerCount;
  final VoidCallback onBack;
  final VoidCallback? onChatAIPressed;

  const RescuerTopNavBar({
    super.key,
    required this.rescuerCount,
    required this.onBack,
    this.onChatAIPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pill trung tâm: luôn nằm chính giữa màn hình tuyệt đối
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 4,
                      backgroundColor: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$rescuerCount người đang hỗ trợ',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Hai nút 2 bên trái & phải
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black87,
                        size: 16,
                      ),
                      onPressed: onBack,
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    elevation: 2,
                    shadowColor: Colors.black12,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap:
                          onChatAIPressed ??
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatVoiAIScreen(),
                              ),
                            );
                          },
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.green,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Chat Với AI',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
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

// 2. NÚT ĐIỀU KHIỂN BẢN ĐỒ
class MapControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;

  const MapControlButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.iconColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}

// 3. THẺ CỨU HỘ VIÊN (TỰ ĐỘNG KHÓA KHI ĐÃ HOÀN THÀNH)
class RescuerItemCard extends StatefulWidget {
  final TrackingRescuerModel item;
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;

  const RescuerItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAvatarTap,
  });

  @override
  State<RescuerItemCard> createState() => _RescuerItemCardState();
}

class _RescuerItemCardState extends State<RescuerItemCard> {
  static final Map<String, ImageProvider?> _avatarCache = {};
  ImageProvider? _avatarImage;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(covariant RescuerItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.nguoiDung.maNguoiDung !=
        widget.item.nguoiDung.maNguoiDung) {
      _loadAvatar();
    }
  }

  Future<void> _loadAvatar() async {
    final userId = widget.item.nguoiDung.maNguoiDung;
    if (userId == null) return;

    if (_avatarCache.containsKey(userId)) {
      if (mounted) setState(() => _avatarImage = _avatarCache[userId]);
      return;
    }

    final raw = await FirebaseService().getUserAvatarUrl(userId);
    ImageProvider? provider;
    if (raw != null && raw.trim().isNotEmpty) {
      final cleaned = raw.trim();
      if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
        provider = NetworkImage(cleaned);
      } else {
        try {
          final base64Str = cleaned.contains(',')
              ? cleaned.split(',').last.trim()
              : cleaned;
          provider = MemoryImage(base64Decode(base64Str));
        } catch (_) {}
      }
    }
    _avatarCache[userId] = provider;
    if (mounted) {
      setState(() => _avatarImage = provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final String status = item.phanCong.maTrangThaiTiepNhan;

    final bool isArrived = status == 'cuuho_trangthai_phancong_daden';
    final bool isRescuing = status == 'cuuho_trangthai_phancong_dangcuuho';
    final bool isCompleted = status == 'cuuho_trangthai_phancong_hoanthanh';

    Color cardBgColor = Colors.white;
    Color borderColor = Colors.grey[200]!;
    double borderWidth = 1.0;

    if (isCompleted) {
      cardBgColor = const Color(0xFFEFF6FF);
      borderColor = Colors.blueAccent;
      borderWidth = 1.5;
    } else if (isRescuing) {
      cardBgColor = const Color(0xFFFFF7ED);
      borderColor = Colors.orange;
      borderWidth = 1.5;
    } else if (isArrived) {
      cardBgColor = const Color(0xFFE2F7F2);
      borderColor = const Color(0xFF0C5C4D);
      borderWidth = 1.5;
    }

    return GestureDetector(
      onTap: isCompleted ? null : widget.onTap,
      child: Opacity(
        opacity: isCompleted ? 0.85 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: isCompleted
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.blueAccent,
                        size: 16,
                      )
                    : Text(
                        '${item.index}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isCompleted ? null : widget.onAvatarTap,
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? Colors.blueAccent
                          : const Color(0xFF0C5C4D),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: isCompleted
                        ? Colors.blueAccent
                        : const Color(0xFF0C5C4D),
                    backgroundImage: _avatarImage,
                    child: _avatarImage == null
                        ? Text(
                            item.nguoiDung.hoTen.isNotEmpty
                                ? item.nguoiDung.hoTen
                                      .substring(0, 1)
                                      .toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nguoiDung.hoTen,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (isCompleted)
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 13,
                            color: Colors.blueAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ĐÃ HOÀN THÀNH CỨU HỘ',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      )
                    else if (isRescuing)
                      const Text(
                        'ĐANG TIẾN HÀNH CỨU HỘ',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    else if (isArrived)
                      const Text(
                        'ĐÃ ĐẾN NƠI',
                        style: TextStyle(
                          color: Color(0xFF0C5C4D),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    else
                      Row(
                        children: [
                          Text(
                            '${item.estimatedTimeMinutes} phút',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const Text(
                            '  •  ',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                          Text(
                            '${item.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Đã xong',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                )
              else
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF0F172A),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.phone,
                      size: 14,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      showEmergencyContactSheet(
                        context,
                        rescuerName: item.nguoiDung.hoTen,
                        rescuerPhone: item.nguoiDung.soDienThoai,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 4. DANH SÁCH CỨU HỘ BÊN DƯỚI
class RescuerListBottomSheet extends StatelessWidget {
  final List<TrackingRescuerModel> trackingList;
  final String maYeuCau;
  final String currentUserId;
  final double victimLat;
  final double victimLng;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final Function(double lat, double lng)? onRescuerTap;
  final Function(TrackingRescuerModel item)? onRescuerAvatarTap;

  const RescuerListBottomSheet({
    super.key,
    required this.trackingList,
    required this.maYeuCau,
    required this.currentUserId,
    required this.victimLat,
    required this.victimLng,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.onRescuerTap,
    this.onRescuerAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    bool hasCompletedRescuer = trackingList.any(
      (r) =>
          r.phanCong.maTrangThaiTiepNhan ==
          'cuuho_trangthai_phancong_hoanthanh',
    );
    String defaultRescuerId = trackingList.isNotEmpty
        ? trackingList.first.nguoiDung.maNguoiDung ?? 'nguoidung2'
        : 'nguoidung2';

    return Container(
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
        children: [
          GestureDetector(
            onTap: onToggleCollapse,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046450),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text(
                      'Nhắn Tin',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatVoiBacSiScreen(
                            maPhongChat: maYeuCau,
                            maNguoiCuuHo: defaultRescuerId,
                            targetName: 'Đội ngũ Cứu hộ',
                            targetAvatar:
                                'https://ui-avatars.com/api/?name=Cuu+Ho&background=046450&color=fff',
                            victimLat: victimLat,
                            victimLng: victimLng,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasCompletedRescuer
                          ? Colors.blueAccent
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      'Hoàn thành',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: hasCompletedRescuer
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HoanThanhDonCuuHoScreen(
                                  maYeuCau: maYeuCau,
                                  currentUserId: currentUserId,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          if (!isCollapsed)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Người cứu hộ tiếp nhận',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F7F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${trackingList.length} người',
                          style: const TextStyle(
                            color: Color(0xFF0C5C4D),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (trackingList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Đang chờ người cứu hộ tiếp nhận...',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...trackingList.map(
                      (item) => RescuerItemCard(
                        item: item,
                        onAvatarTap: () {
                          if (onRescuerAvatarTap != null) {
                            onRescuerAvatarTap!(item);
                          }
                        },
                        onTap: () {
                          if (onRescuerTap != null &&
                              item.nguoiDung.viDo != null &&
                              item.nguoiDung.kinhDo != null) {
                            onRescuerTap!(
                              item.nguoiDung.viDo!,
                              item.nguoiDung.kinhDo!,
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
