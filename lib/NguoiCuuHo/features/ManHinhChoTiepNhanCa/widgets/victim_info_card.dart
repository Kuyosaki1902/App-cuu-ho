import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/emergency_alert_controller.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/alert_style.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/rescue_theme.dart';

/// Thông tin để cứu hộ viên quyết định nhận ca: nạn nhân, địa chỉ, mô tả hiện trường.
/// Chỉ hiển thị phần có dữ liệu thật, không còn dòng "có video" cố định.
class VictimInfoCard extends StatelessWidget {
  const VictimInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EmergencyAlertController>();
    final style = AlertStyle.of(c.mucDoKhanCap);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: rcCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: style.soft,
                child: Icon(Icons.person, color: style.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.victimName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: RC.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.hasVictimPhone
                          ? c.victimPhone
                          : 'Chưa có số điện thoại',
                      style: const TextStyle(
                        fontSize: 13,
                        color: RC.muted,
                        fontFeatures: RC.tabular,
                      ),
                    ),
                  ],
                ),
              ),
              RcRoundButton(
                icon: Icons.phone,
                color: RC.green,
                tooltip: 'Gọi nạn nhân',
                onTap: c.hasVictimPhone ? c.makePhoneCall : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RC.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place, color: style.color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.address,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          color: RC.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (c.isVictimLocationApproximate) ...[
                  const SizedBox(height: 8),
                  const RcPill(
                    text: 'Vị trí lấy từ hồ sơ, có thể không chính xác',
                    fg: RC.amber,
                    bg: RC.amberSoft,
                    icon: Icons.info_outline,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: c.hasVictimLocation
                            ? c.openExternalNavigation
                            : null,
                        icon: const Icon(Icons.navigation_outlined, size: 18),
                        label: const Text('Xem đường đi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RC.blue,
                          minimumSize: const Size(0, 44),
                          side: const BorderSide(color: RC.line),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: c.hasVictimLocation
                            ? () async {
                                await Clipboard.setData(
                                  ClipboardData(
                                    text:
                                        '${c.victimLocation.latitude}, ${c.victimLocation.longitude}',
                                  ),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã sao chép toạ độ'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Sao chép toạ độ'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RC.body,
                          minimumSize: const Size(0, 44),
                          side: const BorderSide(color: RC.line),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (c.hasFieldInfo) ...[
            const SizedBox(height: 14),
            const Text(
              'Người báo tin mô tả',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: RC.ink,
              ),
            ),
            if (c.trieuChung.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in c.trieuChung)
                    RcPill(text: t, fg: style.color, bg: style.soft),
                ],
              ),
            ],
            if (c.moTaChiTiet.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                c.moTaChiTiet,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: RC.body,
                ),
              ),
            ],
            if (c.hinhAnhUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _openPhoto(context, c.hinhAnhUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.network(
                      c.hinhAnhUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) => p == null
                          ? child
                          : const Center(
                              child: CircularProgressIndicator(color: RC.red),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        color: RC.surface,
                        alignment: Alignment.center,
                        child: const Text(
                          'Không tải được ảnh hiện trường',
                          style: TextStyle(color: RC.muted, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Chạm vào ảnh để phóng to',
                  style: TextStyle(fontSize: 12, color: RC.muted),
                ),
              ),
            ],
            if (c.ghiAmUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => c.openUrl(c.ghiAmUrl),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Nghe ghi âm báo tin'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: RC.green,
                  minimumSize: const Size(0, 46),
                  side: const BorderSide(color: RC.greenLine),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _openPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
