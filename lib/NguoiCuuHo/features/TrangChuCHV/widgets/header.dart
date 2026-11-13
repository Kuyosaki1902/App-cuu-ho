import 'dart:typed_data';
import 'package:cuhokhancap/NguoiCuuHo/Features/ManHinhChoTiepNhanCa/ManHinhCho.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/controllers/trang_chu_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LifeguardProfileHeader extends StatelessWidget {
  final bool isOnline;
  final String? name;
  final String? role;
  final String? maVaiTro;

  /// Avatar đã giải mã sẵn (cache ở controller) - không decode lại mỗi lần build.
  final Uint8List? avatarBytes;
  final int capDoUyTin;
  final ValueChanged<bool> onOnlineChanged;
  final VoidCallback? onExitToUserMode;

  const LifeguardProfileHeader({
    super.key,
    required this.isOnline,
    required this.onOnlineChanged,
    required this.name,
    required this.role,
    required this.maVaiTro,
    required this.avatarBytes,
    this.capDoUyTin = 1,
    this.onExitToUserMode,
  });

  void _showOfflineConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
            'Bạn có chắc chắn muốn dừng chế độ trực chiến không? Hệ thống sẽ tạm dừng chia sẻ GPS và nhận ca khẩn cấp.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
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
                Navigator.pop(dialogContext);
                onOnlineChanged(false);
              },
              child: const Text(
                'Xác nhận',
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

  Widget _buildRoleBadge() {
    if (maVaiTro == 'vaitro_cuuhococc') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 12, color: Color(0xFF166534)),
            SizedBox(width: 4),
            Text(
              'ĐÃ DUYỆT',
              style: TextStyle(
                color: Color(0xFF166534),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    if (maVaiTro == 'vaitro_cuuhochuacocc') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '• Độ Uy Tín: $capDoUyTin',
          style: const TextStyle(
            color: Color(0xFF4338CA),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final radiusText = TrangChuController.kNearbyRadiusMeters.toStringAsFixed(
      0,
    );

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Row 1: Profile & Action Icons
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isOnline
                            ? const Color(0xFF10B981)
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF0284C7),
                      backgroundImage: avatarBytes != null
                          ? MemoryImage(avatarBytes!)
                          : null,
                      child: avatarBytes == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF10B981)
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // Name + Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            maVaiTro == 'vaitro_cuuhococc'
                                ? 'BS. ${name ?? 'Đang cập nhật'}'
                                : 'CHV. ${name ?? 'Đang cập nhật'}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildRoleBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 13,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            role ?? 'Đang cập nhật',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 🟢 Chuông thông báo: chỉ còn Badge thật (đã bỏ chấm đỏ luôn bật)
              Consumer<TrangChuController>(
                builder: (context, controller, child) {
                  return Badge(
                    isLabelVisible: controller.soThongBaoChuaDoc > 0,
                    label: Text(
                      '${controller.soThongBaoChuaDoc}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        size: 28,
                        color: Color(0xFF0F172A),
                      ),
                      onPressed: () =>
                          _showNotificationBottomSheet(context, controller),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Banner Trực chiến
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOnline
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFFECACA),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline
                            ? 'ĐANG TRỰC CHIẾN - SẴN SÀNG'
                            : 'NGỪNG TRỰC CHIẾN',
                        style: TextStyle(
                          color: isOnline
                              ? const Color(0xFF065F46)
                              : const Color(0xFF991B1B),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_searching_rounded,
                            size: 11,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline
                                ? 'GPS trực tiếp • Bán kính ${radiusText}m'
                                : 'Đã tắt chia sẻ GPS',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isOnline,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF10B981),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade400,
                    onChanged: (newValue) {
                      if (!newValue) {
                        _showOfflineConfirmationDialog(context);
                      } else {
                        onOnlineChanged(true);
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

void _showNotificationBottomSheet(
  BuildContext parentContext,
  TrangChuController controller,
) {
  showModalBottomSheet(
    context: parentContext,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      // 🟢 AnimatedBuilder: danh sách cập nhật realtime khi sheet đang mở
      // (sheet nằm ngoài cây Provider nên lắng nghe trực tiếp controller)
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final list = controller.danhSachThongBao;
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thông báo cứu hộ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text('Không có thông báo nào trong ngày'),
                        )
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final bool isChuaTiepNhan =
                                item['maTrangThaiTiepNhan'] ==
                                'cuuho_trangthai_phancong_chotiepnhan';
                            final String maYeuCau =
                                (item['maYeuCau'] ?? '').toString().isNotEmpty
                                ? item['maYeuCau'].toString()
                                : item['id'].toString();
                            String trangThai = '';
                            switch (item['maTrangThaiTiepNhan']) {
                              case 'cuuho_trangthai_phancong_chotiepnhan':
                                trangThai = 'Chờ tiếp nhận';
                                break;
                              case 'cuuho_trangthai_phancong_tiepnhan':
                                trangThai = 'Tiếp nhận';
                                break;
                              case 'cuuho_trangthai_phancong_tuchoi':
                                trangThai = 'Từ chối';
                                break;
                              case 'cuuho_trangthai_phancong_hoanthanh':
                                trangThai = 'Hoàn thành';
                                break;
                              default:
                                trangThai = 'Đã hủy';
                                break;
                            }
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isChuaTiepNhan
                                    ? const Color(0xFFFEF2F2)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isChuaTiepNhan
                                      ? Colors.red.shade200
                                      : Colors.transparent,
                                ),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.warning_amber_rounded,
                                  color: isChuaTiepNhan
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                title: Text(
                                  isChuaTiepNhan
                                      ? '🚨 Ca cứu hộ mới cần tiếp nhận'
                                      : 'Thông báo ca cứu hộ',
                                  style: TextStyle(
                                    fontWeight: isChuaTiepNhan
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text('Mã yêu cầu: $maYeuCau'),
                                trailing: isChuaTiepNhan
                                    ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(sheetContext);
                                          // 🟢 Điều hướng tới màn hình chờ tiếp nhận ca
                                          Navigator.push(
                                            parentContext,
                                            MaterialPageRoute(
                                              builder: (_) => Manhinhcho(
                                                currentUserId:
                                                    controller.userID,
                                                maYeuCauCuuHo: maYeuCau,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Xem ca',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        trangThai.isNotEmpty
                                            ? trangThai
                                            : 'Đang cập nhật',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
