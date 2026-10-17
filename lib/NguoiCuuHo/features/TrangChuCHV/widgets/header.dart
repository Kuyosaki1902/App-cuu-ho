import 'package:cuhokhancap/core/color/Color_CHV.dart';
import 'package:flutter/material.dart';

class LifeguardProfileHeader extends StatelessWidget {
  final bool isOnline;
  final String? name;
  final String? role;
  final String? image;
  final ValueChanged<bool> onOnlineChanged;
  final VoidCallback? onExitToUserMode;

  const LifeguardProfileHeader({
    super.key,
    required this.isOnline,
    required this.onOnlineChanged,
    required this.name,
    required this.role,
    required this.image,
    this.onExitToUserMode,
  });

  /// 🟢 Hộp thoại xác nhận khi TẮT trạng thái hoạt động
  void _showOfflineConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.power_settings_new, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Ngừng hoạt động?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn chuyển sang trạng thái Ngừng hoạt động không? Hệ thống sẽ tạm dừng chia sẻ GPS và nhận thông báo ca cứu hộ mới.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                onOnlineChanged(false);
              },
              child: const Text(
                'Xác nhận ngừng',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Hộp thoại xác nhận khi THOÁT CHẾ ĐỘ cứu hộ viên
  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.swap_horiz, color: Color(0xFFB71C1C)),
              SizedBox(width: 8),
              Text(
                'Chuyển vai trò',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn thoát khỏi chế độ Cứu hộ viên và quay lại Màn hình người dùng không?',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                if (onExitToUserMode != null) {
                  onExitToUserMode!();
                }
              },
              child: const Text(
                'Đồng ý',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              // Ảnh đại diện
              image != null
                  ? CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(image!),
                    )
                  : const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Đang cập nhật',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      role ?? 'Đang cập nhật',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // 1. Nút Thông báo
              IconButton(
                onPressed: () {
                  if (isOnline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bạn đang online. Vui lòng tắt chế độ online để nhận thông báo.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bạn đang offline. Không thể nhận thông báo.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notifications_none_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 8),

              // 🟢 2. Nút THOÁT CHẾ ĐỘ CỨU HỘ VIÊN (Nằm ở bên phải ngoài cùng + Viền tròn hoàn chỉnh)
              IconButton(
                tooltip: 'Thoát chế độ Cứu hộ viên',
                onPressed: () {
                  if (isOnline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vui lòng tắt chế độ "Đang sẵn sàng nhận ca" trước khi chuyển vai trò!',
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  _showExitConfirmationDialog(context);
                },
                icon: const Icon(
                  Icons.change_circle_sharp,
                  color: Colors.redAccent,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF1F2),
                  shape: const CircleBorder(
                    side: BorderSide(color: Color(0xFFFECDD3), width: 1.2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Thanh trạng thái Online / Offline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFFF0FDF4)
                  : const Color.fromARGB(255, 249, 219, 219),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: isOnline
                      ? ColorCHV.tiep_nhan_yeu_cau
                      : ColorCHV.ngung_tiep_nhan_yeu_cau,
                  size: 10,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'Đang sẵn sàng nhận ca' : 'Ngừng hoạt động',
                        style: TextStyle(
                          color: isOnline
                              ? ColorCHV.tiep_nhan_yeu_cau
                              : ColorCHV.ngung_tiep_nhan_yeu_cau,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isOnline
                            ? 'Chia sẻ vị trí GPS'
                            : 'Ngừng chia sẻ vị trí GPS',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Switch Bật/Tắt có xác nhận khi ngắt kết nối
                Switch(
                  value: isOnline,
                  activeColor: ColorCHV.tiep_nhan_yeu_cau,
                  onChanged: (newValue) {
                    if (!newValue) {
                      _showOfflineConfirmationDialog(context);
                    } else {
                      onOnlineChanged(true);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
