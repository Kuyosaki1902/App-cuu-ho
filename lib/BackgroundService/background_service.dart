import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class EmergencyNotificationService {
  static final EmergencyNotificationService _instance =
      EmergencyNotificationService._internal();
  factory EmergencyNotificationService() => _instance;
  EmergencyNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<QuerySnapshot>? _assignmentSubscription;

  /// Khởi tạo kênh thông báo local
  Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'rescue_channel_id',
      'Thông báo Cứu hộ Khẩn cấp',
      description: 'Kênh nhận thông báo phân công ca cứu hộ mới',
      importance: Importance.max,
      playSound: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Bắt đầu lắng nghe đơn cứu hộ khi mở app
  void startListening(String userId) {
    if (userId.isEmpty) return;

    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    debugPrint(
      '🟢 [Foreground] Bắt đầu lắng nghe đơn cứu hộ cho user: $userId ngày $todayStr',
    );

    _assignmentSubscription?.cancel();
    _assignmentSubscription = FirebaseFirestore.instance
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
                debugPrint('🚨 [Foreground] Phát hiện ca cứu hộ mới!');
                _showEmergencyNotification(
                  title: '🚨 CÓ YÊU CẦU CỨU HỘ MỚI!',
                  body: 'Bạn có ca cấp cứu mới cần xử lý ngay lập tức.',
                );
              }
            }
          },
          onError: (e) {
            debugPrint('❌ [Foreground] Lỗi Stream: $e');
          },
        );
  }

  /// Dừng lắng nghe khi thoát màn hình hoặc đăng xuất
  void stopListening() {
    debugPrint('🔴 [Foreground] Dừng lắng nghe đơn cứu hộ');
    _assignmentSubscription?.cancel();
    _assignmentSubscription = null;
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

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('Lỗi hiển thị Notification: $e');
    }
  }
}
