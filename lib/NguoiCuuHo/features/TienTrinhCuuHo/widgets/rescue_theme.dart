import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// Bảng màu và kiểu dùng chung cho màn hình tiến trình cứu hộ.
///
/// Màu mang nghĩa trạng thái: xanh đen = đang di chuyển, xanh lá = đã đến nơi,
/// đỏ = đang cứu nạn / hành động chính / cảnh báo.
class RC {
  RC._();

  static const red = Color(0xFFD92D20);
  static const redDark = Color(0xFFB42318);
  static const redSoft = Color(0xFFFEF3F2);
  static const redLine = Color(0xFFFECDCA);

  static const ink = Color(0xFF1D2939);
  static const body = Color(0xFF475467);
  static const muted = Color(0xFF667085);
  static const line = Color(0xFFE4E7EC);
  static const surface = Color(0xFFF2F4F7);

  static const green = Color(0xFF067647);
  static const greenLight = Color(0xFF75E0A7);
  static const greenSoft = Color(0xFFECFDF3);
  static const greenLine = Color(0xFFABEFC6);

  static const amber = Color(0xFFB54708);
  static const amberSoft = Color(0xFFFFFAEB);
  static const amberLine = Color(0xFFFEDF89);

  static const blue = Color(0xFF175CD3);
  static const blueSoft = Color(0xFFEFF8FF);

  /// Chữ số đều nhau để số đếm không "nhảy" khi thay đổi.
  static const tabular = [FontFeature.tabularFigures()];

  static List<BoxShadow> get shadow => [
    BoxShadow(
      color: const Color(0xFF101828).withOpacity(0.12),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
  ];
}

String _two(int n) => n.toString().padLeft(2, '0');

/// "09:40" hoặc "--:--" khi chưa có dữ liệu.
String clock(DateTime? t) => t == null ? '--:--' : '${_two(t.hour)}:${_two(t.minute)}';

BoxDecoration rcCardDecoration({
  Color color = Colors.white,
  double radius = 16,
  bool shadow = false,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: RC.line),
    boxShadow: shadow ? RC.shadow : null,
  );
}

/// Nhãn nhỏ có nền, dùng cho trạng thái / triệu chứng.
class RcPill extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  final IconData? icon;

  const RcPill({
    super.key,
    required this.text,
    required this.fg,
    required this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút tròn 44 dp (đủ vùng chạm) dùng cho gọi / nhắn tin.
class RcRoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;

  const RcRoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onTap == null ? RC.line : color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Thanh nắm kéo của bottom sheet.
class RcGrabHandle extends StatelessWidget {
  const RcGrabHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 12),
        decoration: BoxDecoration(
          color: RC.line,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
