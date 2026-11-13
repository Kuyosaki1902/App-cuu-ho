import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/TrangChu_NCH.dart';
import 'package:flutter/material.dart';

/// Xóa toàn bộ stack và đưa cứu hộ viên về trang chủ.
void goToRescuerHome(BuildContext context, String currentUserId) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => Trangchunguoicuuho(currentUserId: currentUserId),
    ),
    (route) => false,
  );
}
