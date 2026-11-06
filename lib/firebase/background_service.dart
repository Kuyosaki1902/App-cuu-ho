import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  
  // SỬA TẠI ĐÂY: Đọc đúng key 'maNguoiDung_daLuu' mà main.dart đã lưu
  String? maNguoiDungHienTai = prefs.getString('maNguoiDung_daLuu'); 
  
  // Dự phòng nếu app truyền key 'maNguoiDung'
  maNguoiDungHienTai ??= prefs.getString('maNguoiDung');

  // Nếu người dùng chưa đăng nhập / không ghi nhớ đăng nhập thì dừng service
  if (maNguoiDungHienTai == null || maNguoiDungHienTai.isEmpty) {
    service.stopSelf();
    return;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Khởi tạo notification plugin cho background
  const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Lắng nghe Firestore Realtime
  FirebaseFirestore.instance
      .collectionGroup('DanhSachNguoiThan')
      .where('maNguoiThan', isEqualTo: maNguoiDungHienTai)
      .where('trangThai', isEqualTo: 'dangGoi')
      .snapshots()
      .listen((snapshot) async {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
        final data = change.doc.data();
        if (data != null) {
          String maNguoiGoi = data['maNguoiDung'];
          
          // Truy vấn họ tên
          final userDoc = await FirebaseFirestore.instance.collection('NguoiDung').doc(maNguoiGoi).get();
          String hoTen = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['hoTen'] ?? maNguoiGoi : maNguoiGoi;

          // Bắn notification đè màn hình + Chuông + Rung
          flutterLocalNotificationsPlugin.show(
            change.doc.id.hashCode,
            '🚨 CẢNH BÁO KHẨN CẤP',
            'Người thân $hoTen đang gặp nguy hiểm!',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'sos_channel_id_v3',
                'Cảnh báo khẩn cấp',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                fullScreenIntent: true,
              ),
            ),
          );

          // Đọc giọng nói khẩn cấp bằng TTS
          FlutterTts flutterTts = FlutterTts();
          await flutterTts.setLanguage("vi-VN");
          await flutterTts.setSpeechRate(0.5);
          await flutterTts.setVolume(1.0);
          await flutterTts.speak("Cảnh báo khẩn cấp. Người thân $hoTen đang gặp nguy hiểm!");
        }
      }
    }
  });
}