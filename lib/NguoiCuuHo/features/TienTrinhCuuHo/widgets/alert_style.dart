import 'package:flutter/material.dart';

// Dùng lại bảng màu của module tiến trình cứu hộ để hai màn hình đồng bộ.
import 'package:cuhokhancap/NguoiCuuHo/Features/TienTrinhCuuHo/widgets/rescue_theme.dart';

/// Màu và nhãn theo mức độ khẩn cấp (1 = nguy kịch, còn lại = cấp 2 trở lên).
class AlertStyle {
  final Color color;
  final Color soft;
  final Color line;
  final String label;

  const AlertStyle._(this.color, this.soft, this.line, this.label);

  factory AlertStyle.of(int mucDo) {
    if (mucDo == 1) {
      return const AlertStyle._(RC.red, RC.redSoft, RC.redLine, 'Nguy kịch');
    }
    return AlertStyle._(RC.amber, RC.amberSoft, RC.amberLine, 'Cấp độ $mucDo');
  }
}
