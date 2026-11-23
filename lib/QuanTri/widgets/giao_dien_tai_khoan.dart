import 'package:flutter/material.dart';

import '../features/TaiKhoan/models/tai_khoan_model.dart';
import 'giao_dien_xac_minh.dart';

const accountBlue = Color(0xFF1565C0);
const accountCanvas = Color(0xFFF6F7FB);
const accountPanel = Color(0xFFF0F4FA);
ThemeData accountTheme(BuildContext context) =>
    verificationTheme(context).copyWith(
      scaffoldBackgroundColor: accountCanvas,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E7F0)),
        ),
      ),
    );
Widget accountBadge(String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  decoration: BoxDecoration(
    color: color.withValues(alpha: .10),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    label,
    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
  ),
);
String accountState(TaiKhoan a) => a.locked
    ? 'Bị khóa'
    : a.suspended
    ? 'Tạm ngừng nhận ca'
    : a.canSupport
    ? 'Sẵn sàng hỗ trợ'
    : a.status == 'hoat_dong'
    ? 'Đang hoạt động'
    : 'Chưa cập nhật trạng thái';
Color accountStateColor(TaiKhoan a) => a.locked
    ? const Color(0xFFCE3434)
    : a.suspended
    ? const Color(0xFFD58A12)
    : a.status == 'hoat_dong'
    ? const Color(0xFF32854A)
    : const Color(0xFF71829B);
Color accountTypeColor(TaiKhoan a) =>
    a.professional != null && a.volunteer != null
    ? const Color(0xFF9A6700)
    : a.professional != null
    ? const Color(0xFF1D4ED8)
    : a.volunteer != null
    ? const Color(0xFF0F766E)
    : const Color(0xFF7E22CE);
String accountTypeLabel(TaiKhoan a) =>
    a.professional != null && a.volunteer != null
    ? 'Có 2 loại hồ sơ'
    : a.professional != null
    ? 'Có CCHN'
    : a.volunteer != null
    ? 'Không CCHN'
    : 'Người dùng';

class AnhDaiDienTaiKhoan extends StatelessWidget {
  final TaiKhoan account;
  final double radius;
  const AnhDaiDienTaiKhoan(this.account, {super.key, this.radius = 25});
  @override
  Widget build(BuildContext context) {
    final words = account.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final initials = words
        .take(2)
        .map((w) => w.characters.first)
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: accountTypeColor(account).withValues(alpha: .12),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: accountTypeColor(account),
          fontWeight: FontWeight.bold,
          fontSize: radius * .65,
        ),
      ),
    );
  }
}

class DieuHuongTaiKhoan extends StatelessWidget {
  final VoidCallback onVerification;
  final VoidCallback? onRequests, onReports, onSkills;
  const DieuHuongTaiKhoan({
    super.key,
    required this.onVerification,
    this.onRequests,
    this.onReports,
    this.onSkills,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE0E7F0))),
    ),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          item(Icons.emergency_outlined, 'Yêu cầu', onRequests),
          item(Icons.people_outline, 'Tài khoản', () {}, selected: true),
          item(Icons.verified_user_outlined, 'Xác minh', onVerification),
          item(Icons.query_stats_rounded, 'Báo cáo', onReports),
          item(Icons.medical_services_outlined, 'Kỹ năng', onSkills),
        ],
      ),
    ),
  );
  Widget item(
    IconData icon,
    String label,
    VoidCallback? action, {
    bool selected = false,
  }) => mucDieuHuong(icon, label, action, selected: selected);
}

Widget mucDieuHuong(
  IconData icon,
  String label,
  VoidCallback? action, {
  bool selected = false,
  int badge = 0,
}) => Expanded(
  child: Semantics(
    selected: selected,
    button: true,
    child: Tooltip(
      message: action == null ? '$label — chưa khả dụng' : label,
      child: InkWell(
        onTap: action,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFDCEBFF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected
                        ? accountBlue
                        : action == null
                        ? const Color(0xFFAAB4C4)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accountBlue : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
