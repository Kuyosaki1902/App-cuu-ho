import 'dart:async';
import 'QuanTri/features/YeuCauHoTro/services/thong_bao_day_service.dart';
import 'QuanTri/widgets/giao_dien_tai_khoan.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'QuanTri/features/DangNhap/dang_nhap_screen.dart';
import 'QuanTri/core/ket_noi_gia_lap.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const bool.fromEnvironment('USE_EMULATORS')
        ? const FirebaseOptions(
            apiKey: 'demo-key',
            appId: '1:123:web:demo',
            messagingSenderId: '123',
            projectId: 'demo-cuu-ho',
          )
        : DefaultFirebaseOptions.currentPlatform,
  );

  if (const bool.fromEnvironment('USE_EMULATORS')) {
    await connectAdminEmulators(
      host: const String.fromEnvironment(
        'EMULATOR_HOST',
        defaultValue: '127.0.0.1',
      ),
    );
  }
  runApp(const MyApp());

  if (!const bool.fromEnvironment('USE_EMULATORS')) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ThongBaoDayService.instance.start().catchError((Object error) {
          debugPrint('Không khởi tạo được thông báo: ${error.runtimeType}');
        }),
      );
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản trị cứu hộ khẩn cấp',
      theme: accountTheme(context),
      home: const DangNhapScreen(),
    );
  }
}
