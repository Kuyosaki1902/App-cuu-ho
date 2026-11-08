import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:intl/intl.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'rescue_channel_id',
    'Thông báo Cứu hộ Khẩn cấp',
    description: 'Kênh nhận thông báo phân công ca cứu hộ mới',
    importance: Importance.max,
    playSound: true,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initializationSettingsAndroid),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart:
          false, // 🟢 ĐỔI THÀNH FALSE: Chỉ khởi động khi Cứu hộ viên bật Online
      isForegroundMode: true,
      notificationChannelId: 'rescue_channel_id',
      initialNotificationTitle: 'Dịch vụ Cứu hộ Khẩn cấp',
      initialNotificationContent: 'Hệ thống đang sẵn sàng nhận ca...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  SharedPreferencesAndroid.registerWith();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Lỗi khởi tạo Firebase Isolate: $e');
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? assignmentSubscription;

  // Hàm thực hiện lắng nghe Firestore
  void listenToAssignments(String userId) {
    if (userId.isEmpty) return;

    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    debugPrint(
      '🟢 [BackgroundService] Bắt đầu lắng nghe đơn cứu hộ cho user: $userId ngày $todayStr',
    );

    assignmentSubscription?.cancel();
    assignmentSubscription = firestore
        .collection('ChiTietPhanCongCuuHo')
        .doc(userId)
        .collection('DanhSachNgay')
        .doc(todayStr)
        .collection('DanhSachPhanCong')
        .where(
          'maTrangThaiTiepNhan',
          isEqualTo: 'cuuho_trangthai_phancong_chotiepnhan',
        )
        .snapshots()
        .listen(
          (snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                debugPrint('🚨 [BackgroundService] Phát hiện ca cứu hộ mới!');
                _showEmergencyNotification(
                  title: '🚨 CÓ YÊU CẦU CỨU HỘ MỚI!',
                  body: 'Bạn có ca cấp cứu mới cần xử lý ngay lập tức.',
                );
              }
            }
          },
          onError: (e) {
            debugPrint('❌ [BackgroundService] Lỗi Stream: $e');
          },
        );
  }

  // Nhận lệnh từ UI chính
  service.on('startListening').listen((event) {
    String userId = event?['userId'] ?? '';
    listenToAssignments(userId);
  });

  service.on('stopListening').listen((event) {
    debugPrint('🔴 [BackgroundService] Dừng lắng nghe');
    assignmentSubscription?.cancel();
  });
}

Future<void> _showEmergencyNotification({
  required String title,
  required String body,
}) async {
  try {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'rescue_channel_id',
          'Thông báo Cứu hộ Khẩn cấp',
          channelDescription: 'Kênh nhận thông báo phân công ca cứu hộ mới',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          playSound: true,
        );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  } catch (e) {
    debugPrint('Lỗi hiển thị Notification: $e');
  }
}
