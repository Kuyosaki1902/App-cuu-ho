import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';

// Hàm khởi tạo dịch vụ nền
Future<void> initializeBackgroundService(String currentRelativeUserId) async {
  final service = FlutterBackgroundService();

  // Khởi tạo kênh thông báo cho Foreground Service trên Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'emergency_service_channel',
    'Kênh Cứu Hộ Khẩn Cấp',
    description: 'Dịch vụ chạy ngầm lắng nghe tín hiệu SOS từ người thân',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'emergency_service_channel',
      initialNotificationTitle: 'Hệ thống cứu hộ đang hoạt động',
      initialNotificationContent:
          'Đang bảo vệ và lắng nghe tín hiệu khẩn cấp...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  // Truyền ID của người thân vào service khi khởi động
  service.invoke("setUserId", {"userId": currentRelativeUserId});
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  String? currentUserId;
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  StreamSubscription<QuerySnapshot>? callSubscription;

  service.on("setUserId").listen((event) {
    if (event != null && event['userId'] != null) {
      currentUserId = event['userId'];

      // Bắt đầu lắng nghe Firestore ngay khi nhận được ID
      _startListening(currentUserId!, flutterTts, audioPlayer, service);
    }
  });
}

// Thêm thư viện hiển thị thông báo cục bộ vào service ngầm

void _startListening(
  String userId,
  FlutterTts flutterTts,
  AudioPlayer audioPlayer,
  ServiceInstance service,
) {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  FirebaseFirestore.instance
      .collectionGroup('DanhSachNguoiThan')
      .where('maNguoiThan', isEqualTo: userId)
      .where('trangThai', isEqualTo: 'dangGoi')
      .snapshots()
      .listen((snapshot) async {
        if (snapshot.docs.isNotEmpty) {
          var doc = snapshot.docs.first;
          var callData = doc.data() as Map<String, dynamic>;
          String message =
              callData['noiDungDoc'] ?? 'Có cuộc gọi khẩn cấp SOS!';

          // 1. Phát nhạc chuông lặp lại
          try {
            await audioPlayer.setReleaseMode(ReleaseMode.loop);
            await audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
          } catch (e) {
            debugPrint('Lỗi phát nhạc chuông ngầm: $e');
          }

          // 2. Đọc văn bản Text-to-Speech
          try {
            await flutterTts.setLanguage("vi-VN");
            await flutterTts.setSpeechRate(0.5);
            await flutterTts.setVolume(1.0);
            await flutterTts.speak(message);
          } catch (e) {
            debugPrint('Lỗi TTS ngầm: $e');
          }

          // 3. 🟢 BẮN NOTIFICATION TOÀN MÀN HÌNH (Hiển thị ngay cả khi Kill App)
          const AndroidNotificationDetails
          androidDetails = AndroidNotificationDetails(
            'emergency_call_channel_id',
            'Cuộc gọi khẩn cấp SOS',
            channelDescription:
                'Kênh thông báo cuộc gọi khẩn cấp từ người thân',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent:
                true, // 👈 Thuộc tính cốt lõi để đánh thức màn hình khi khóa/kill app
            sound: RawResourceAndroidNotificationSound(
              'ringtone',
            ), // Có thể dùng âm thanh mặc định hoặc tuỳ chỉnh
            playSound: true,
            ongoing: true, // Không cho vuốt tắt dễ dàng, giống cuộc gọi thực tế
          );

          const NotificationDetails notificationDetails = NotificationDetails(
            android: androidDetails,
          );

          await flutterLocalNotificationsPlugin.show(
            888,
            '🚨 CẢNH BÁO KHẨN CẤP SOS!',
            message,
            notificationDetails,
            payload: doc
                .reference
                .path, // Truyền đường dẫn Firestore để khi bấm vào sẽ mở đúng cuộc gọi
          );

          // 4. Vẫn gửi sự kiện về UI nếu app đang mở
          service.invoke("triggerCallScreen", {
            "callData": callData,
            "docPath": doc.reference.path,
          });
        }
      });
}
