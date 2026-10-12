import 'package:cuhokhancap/core/color/Color_CHV.dart';
import 'package:flutter/material.dart';

class LifeguardProfileHeader extends StatelessWidget {
  final bool isOnline;
  final String? name;
  final String? role;
  final String? image;
  final ValueChanged<bool> onOnlineChanged;

  const LifeguardProfileHeader({
    super.key,
    required this.isOnline,
    required this.onOnlineChanged,
    required this.name,
    required this.role,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              //Kiểm tra ảnh đại diện
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
                    //Kiểm tra tên
                    Text(
                      name ?? 'Đang cập nhật',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    //Kiểm tra vai trò
                    Text(
                      role ?? 'Đang cập nhật',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (isOnline) {
                    // Hiển thị thông báo khi đang online
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bạn đang online. Vui lòng tắt chế độ online để nhận thông báo.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    // Thực hiện hành động khi đang offline
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOnline,
                  activeColor: ColorCHV.tiep_nhan_yeu_cau,
                  onChanged: onOnlineChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
