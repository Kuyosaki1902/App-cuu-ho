//lib/user/TongQuanBacSiTiepNhan/views/rescuer_overview_components.dart
import 'package:cuhokhancap/user/ChatVoiBacSi/ChatVoiBacSi.dart';
import 'package:cuhokhancap/user/TongQuanBacSiTiepNhan/Models/tracking_rescuer_model.dart';
import 'package:flutter/material.dart';

// 1. THANH ĐIỀU HƯỚNG TRÊN CÙNG (TOP NAV BAR)
class RescuerTopNavBar extends StatelessWidget {
  final int rescuerCount;
  final VoidCallback onBack;
  final VoidCallback onSosPressed;

  const RescuerTopNavBar({
    super.key,
    required this.rescuerCount,
    required this.onBack,
    required this.onSosPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: 20,
                ),
                onPressed: onBack,
              ),
            ),
            const Spacer(),
            // Badge đếm số lượng người đang tới
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 4,
                    backgroundColor: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$rescuerCount người đang đến',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Nút SOS 115
            CircleAvatar(
              backgroundColor: const Color(0xFFFDE8E8),
              radius: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.phone_in_talk,
                  color: Color(0xFFE53E3E),
                  size: 18,
                ),
                onPressed: onSosPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. NÚT ĐIỀU KHIỂN BẢN ĐỒ (MAP CONTROL BUTTON)
class MapControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor; // 🌟 Thêm thuộc tính đổi màu icon

  const MapControlButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.iconColor = Colors.black87, // Mặc định là đen
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
        child: Icon(icon, size: 20, color: iconColor), // Dùng iconColor ở đây
      ),
    );
  }
}

// 3. THẺ THÔNG TIN TỪNG CỨU HỘ VIÊN
class RescuerItemCard extends StatelessWidget {
  final TrackingRescuerModel item;
  final String maYeuCau;
  final String currentUserId;
  final double victimLat; // 🌟 Bổ sung vĩ độ nạn nhân
  final double victimLng; // 🌟 Bổ sung kinh độ nạn nhân
  final VoidCallback? onTap;

  const RescuerItemCard({
    super.key,
    required this.item,
    required this.maYeuCau,
    required this.currentUserId,
    required this.victimLat, // Bắt buộc nhận
    required this.victimLng, // Bắt buộc nhận
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isArrived =
        item.phanCong.maTrangThaiTiepNhan == 'cuuho_trangthai_phancong_daden';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isArrived ? const Color(0xFFE2F7F2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isArrived ? const Color(0xFF0C5C4D) : Colors.grey[200]!,
            width: isArrived ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
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
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF0C5C4D),
              child: Text(
                item.nguoiDung.hoTen.isNotEmpty
                    ? item.nguoiDung.hoTen.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                  if (isArrived)
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
            // Nút CHAT (Truyền đúng victimLat và victimLng sang màn hình Chat)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatVoiBacSiScreen(
                      maPhongChat: maYeuCau,
                      maNguoiCuuHo: item.nguoiDung.maNguoiDung!,
                      currentUserId: currentUserId,
                      targetName: item.nguoiDung.hoTen,
                      targetAvatar:
                          'https://ui-avatars.com/api/?name=${item.nguoiDung.hoTen}&background=046450&color=fff',
                      victimLat: victimLat, // 🌟 Truyền vĩ độ thực tế vào
                      victimLng: victimLng, // 🌟 Truyền kinh độ thực tế vào
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Nút Gọi Điện
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF0F172A),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.phone, size: 14, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ],
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
  final double victimLat; // 🌟 Bổ sung vĩ độ nạn nhân ở đây nữa
  final double victimLng; // 🌟 Bổ sung kinh độ nạn nhân ở đây nữa
  final Function(double lat, double lng)? onRescuerTap;
  final ScrollController scrollController;

  const RescuerListBottomSheet({
    super.key,
    required this.trackingList,
    required this.maYeuCau,
    required this.currentUserId,
    required this.victimLat, // Bắt buộc nhận
    required this.victimLng, // Bắt buộc nhận
    required this.scrollController,
    this.onRescuerTap,
  });

  @override
  Widget build(BuildContext context) {
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
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
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
                maYeuCau: maYeuCau,
                currentUserId: currentUserId,
                victimLat: victimLat, // 🌟 Truyền tiếp xuống RescuerItemCard
                victimLng: victimLng, // 🌟 Truyền tiếp xuống RescuerItemCard
                onTap: () {
                  if (onRescuerTap != null &&
                      item.nguoiDung.viDo != null &&
                      item.nguoiDung.kinhDo != null) {
                    onRescuerTap!(item.nguoiDung.viDo!, item.nguoiDung.kinhDo!);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
