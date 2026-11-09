import 'package:cuhokhancap/BackgroundService/background_service.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/DangKy_DangNhap/DangNhap.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/TrangChu_NCH.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase/firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Permission.notification.request();
  await EmergencyNotificationService().initialize();
  // 2. Kiểm tra xem người dùng đã chọn "Ghi nhớ đăng nhập" từ trước chưa
  final prefs = await SharedPreferences.getInstance();
  final String? maNguoiDungDaLuu = prefs.getString('maNguoiDung_daLuu');
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'), // Tiếng Việt
        Locale('en', 'US'), // Tiếng Anh
      ],
      locale: const Locale('vi', 'VN'), // Đặt mặc định là tiếng Việt
      // Điều hướng thông minh
      home: (maNguoiDungDaLuu != null && maNguoiDungDaLuu!.isNotEmpty)
          ? Trangchunguoicuuho(
              currentUserId: maNguoiDungDaLuu!,
              maThietBiMoi: maThietBiMoi,
            )
          : const DangNhap(),
    );
  }
}
