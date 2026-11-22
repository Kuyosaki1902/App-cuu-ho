import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user/DangNhap.dart';
import 'user/TrangChuNguoiDung.dart';
import 'firebase/firebase_options.dart';
import 'firebase/background_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check (bắt buộc cho Firebase AI Logic):
  // - Debug: dùng debug provider (phải đăng ký debug token trong Firebase Console)
  // - Release: dùng Play Integrity (phải đăng ký app + SHA-256 trong App Check)
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
  );

  // 2. Kiểm tra xem người dùng đã chọn "Ghi nhớ đăng nhập" từ trước chưa
  final prefs = await SharedPreferences.getInstance();
  final String? maNguoiDungDaLuu = prefs.getString('maNguoiDung_daLuu');

  if (maNguoiDungDaLuu != null && maNguoiDungDaLuu.isNotEmpty) {
    await initializeService();
  }
  // 3. Khởi chạy app và truyền biến kiểm tra vào
  runApp(MyApp(maNguoiDungDaLuu: maNguoiDungDaLuu));
}

class MyApp extends StatelessWidget {
  final String? maNguoiDungDaLuu;

  const MyApp({super.key, this.maNguoiDungDaLuu});

  @override
  Widget build(BuildContext context) {
    // THÊM DÒNG NÀY: Sinh mã thiết bị mới khi app tự động đăng nhập
    String maThietBiMoi = DateTime.now().millisecondsSinceEpoch.toString();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cứu Hộ Khẩn Cấp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Điều hướng thông minh
      home: (maNguoiDungDaLuu != null && maNguoiDungDaLuu!.isNotEmpty)
          ? TrangChuNguoiDung(
              maNguoiDung: maNguoiDungDaLuu!,
              maThietBi:
                  maThietBiMoi, // SỬA LỖI TẠI ĐÂY: Truyền mã thiết bị vào
            )
          : const DangNhap(),
    );
  }
}