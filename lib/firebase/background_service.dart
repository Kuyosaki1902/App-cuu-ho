import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'sos_channel_id',
    'Cảnh báo khẩn cấp',
    description: 'Kênh thông báo khi người thân gặp nguy hiểm',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'sos_channel_id',
      initialNotificationTitle: 'Bảo vệ người thân',
      initialNotificationContent: 'Hệ thống đang chạy ngầm để bảo vệ người thân của bạn',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  // Lấy mã người dùng đã đăng nhập (ví dụ: nguoidung1)
  final String? maNguoiDungHienTai = prefs.getString('maNguoiDung'); 

  if (maNguoiDungHienTai == null) return;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // DÙNG TRUY VẤN MỤC HỢP NHẤT (COLLECTION GROUP QUERY)
  FirebaseFirestore.instance
      .collectionGroup('DanhSachNguoiThan')
      .where('maNguoiThan', isEqualTo: maNguoiDungHienTai)
      .where('trangThai', isEqualTo: 'dangGoi')
      .snapshots()
      .listen((snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
        final data = change.doc.data();
        if (data != null) {
          // Bắn thông báo nền
          flutterLocalNotificationsPlugin.show(
            change.doc.id.hashCode,
            '🚨 CẢNH BÁO KHẨN CẤP',
            'Người thân ${data['maNguoiDung']} đang gặp nguy hiểm!',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'sos_channel_id',
                'Cảnh báo khẩn cấp',
                importance: Importance.max,
                priority: Priority.high,
                fullScreenIntent: true, // Hiển thị pop-up ngay cả khi tắt màn hình
              ),
            ),
          );
        }
      }
    }
  });
}