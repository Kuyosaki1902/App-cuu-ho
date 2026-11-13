import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:cuhokhancap/BackgroundService/background_service.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/DangKy_DangNhap/DangNhap.dart';
import 'package:cuhokhancap/NguoiCuuHo/Features/TrangChuCHV/TrangChu_NCH.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase/firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cuhokhancap/firebase/presence_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lỗi Flutter / lỗi async chưa bắt: ghi log (xem bằng adb logcat) thay vì im lặng.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Lỗi chưa bắt: $error\n$stack');
    return true;
  };

  // Vẽ khung hình đầu tiên NGAY. Việc khởi tạo chạy phía sau màn hình tải,
  // nên nếu có lỗi hoặc bị treo thì người dùng thấy thông báo, không phải màn trắng.
  runApp(const _Bootstrap());
}

/// Khởi tạo Firebase, phiên thiết bị, SharedPreferences và thông báo,
/// rồi mới vào MyApp.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<String?> _future = _init();

  Future<String?> _init() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
    }

    await Future<void>.sync(
      () => DeviceSession.init(),
    ).timeout(const Duration(seconds: 10));

    final prefs = await SharedPreferences.getInstance();
    final String? maNguoiDungDaLuu = prefs.getString('maNguoiDung_daLuu');

    // Dịch vụ thông báo không được phép chặn hay làm hỏng việc vào app
    // (initialize() có thể đang chờ người dùng bấm cấp quyền).
    try {
      await Future<void>.sync(
        () => EmergencyNotificationService().initialize(),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Lỗi khởi tạo Notification Service: $e');
    }

    return maNguoiDungDaLuu;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return _BootError(
            error: snap.error!,
            onRetry: () => setState(() => _future = _init()),
          );
        }
        if (snap.connectionState != ConnectionState.done) {
          return const _BootSplash();
        }
        return MyApp(maNguoiDungDaLuu: snap.data);
      },
    );
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _BootError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _BootError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Không khởi động được ứng dụng',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Hiện lỗi thật để chẩn đoán; có thể ẩn đi khi phát hành chính thức.
                Flexible(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final String? maNguoiDungDaLuu;

  const MyApp({super.key, this.maNguoiDungDaLuu});

  @override
  Widget build(BuildContext context) {
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
          ? Trangchunguoicuuho(currentUserId: maNguoiDungDaLuu!)
          : const DangNhap(),
    );
  }
}
