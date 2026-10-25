import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

import 'user/DangNhap.dart';
import 'user/TrangChuNguoiDung.dart'; 
import 'firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Kiểm tra xem người dùng đã chọn "Ghi nhớ đăng nhập" từ trước chưa
  final prefs = await SharedPreferences.getInstance();
  final String? maNguoiDungDaLuu = prefs.getString('maNguoiDung_daLuu');

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
              maThietBi: maThietBiMoi, // SỬA LỖI TẠI ĐÂY: Truyền mã thiết bị vào
            )
          : const DangNhap(),
    );
  }
}