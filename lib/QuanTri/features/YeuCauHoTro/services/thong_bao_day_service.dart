import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ThongBaoDayService {
  ThongBaoDayService._();

  static final instance = ThongBaoDayService._();

  static const MethodChannel _native = MethodChannel(
    'admin_cuuho/local_notifications',
  );

  static const String _urgentChannel = 'admin_cuuho_khan_cap';
  static const String _dispatchChannel = 'admin_cuuho_dieu_phoi';

  final opened = ValueNotifier<Map<String, String>?>(null);

  StreamSubscription<String>? _refresh;
  DocumentReference<Map<String, dynamic>>? _device;
  String? _uid;
  int _generation = 0;
  bool _started = false;
  Future<void>? _starting;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  Future<void> _saving = Future.value();

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> start() async {
    if (!supported || _started) return;
    final activeStart = _starting;
    if (activeStart != null) {
      await activeStart;
      return;
    }

    final startFuture = _startInternal();
    _starting = startFuture;
    try {
      await startFuture;
      _started = true;
    } finally {
      _starting = null;
    }
  }

  Future<void> _startInternal() async {
    _native.setMethodCallHandler((call) async {
      if (call.method != 'notificationTap') return;
      final raw = call.arguments;
      if (raw is Map) {
        _setOpened(Map<String, dynamic>.from(raw));
        await _clearNativePendingTap();
      }
    });

    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundNotification(message));
    });
    _openedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(_open);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _open(initial);

    try {
      final pending = await _native.invokeMapMethod<String, dynamic>(
        'consumePendingNotificationTap',
      );
      if (pending != null) _setOpened(pending);
    } catch (error) {
      debugPrint('Không đọc được thông báo đang chờ mở: ${error.runtimeType}');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final data = message.data;
    final adminUid = data['maAdmin'];
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? _uid;

    if (currentUid == null ||
        adminUid != currentUid ||
        data['maThongBao'] is! String ||
        data['maYeuCau'] is! String) {
      return;
    }

    final title =
        message.notification?.title ??
        (data['tieuDe'] is String
            ? data['tieuDe'] as String
            : 'Thông báo cứu hộ');
    final body =
        message.notification?.body ??
        (data['noiDung'] is String ? data['noiDung'] as String : '');
    final priority = data['mucDoUuTien'] == 'khan_cap'
        ? 'khan_cap'
        : 'quan_trong';
    final channelId = priority == 'khan_cap'
        ? _urgentChannel
        : _dispatchChannel;
    final payload = <String, String>{
      for (final entry in data.entries)
        if (entry.value is String) entry.key: entry.value as String,
    };

    try {
      await _native.invokeMethod<bool>('showLocalNotification', {
        'id': (data['maThongBao'] as String).hashCode & 0x7fffffff,
        'title': title,
        'body': body,
        'channelId': channelId,
        'data': payload,
      });
    } catch (error) {
      debugPrint('Không hiển thị được thông báo nổi: ${error.runtimeType}');
    }
  }

  void _open(RemoteMessage message) => _setOpened(message.data);

  void _setOpened(Map<String, dynamic> data) {
    final requestId = data['maYeuCau'];
    final adminId = data['maAdmin'];
    if (requestId is! String ||
        requestId.isEmpty ||
        requestId.contains('/') ||
        adminId is! String ||
        adminId.isEmpty) {
      return;
    }

    opened.value = {
      'maYeuCau': requestId,
      'maAdmin': adminId,
      'maThongBao': '${data['maThongBao'] ?? ''}',
    };
  }

  Future<void> _clearNativePendingTap() async {
    try {
      await _native.invokeMethod<void>('clearPendingNotificationTap');
    } catch (_) {}
  }

  Future<bool> markAsRead({
    required String notificationId,
    required String adminUid,
  }) async {
    if (notificationId.isEmpty ||
        notificationId.contains('/') ||
        adminUid.isEmpty ||
        FirebaseAuth.instance.currentUser?.uid != adminUid) {
      return false;
    }

    final ref = FirebaseFirestore.instance
        .collection('ThongBao')
        .doc(notificationId);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (!snapshot.exists || data == null || data['maNguoiDung'] != adminUid) {
        return false;
      }
      if (data['daDoc'] != true) {
        transaction.update(ref, {'daDoc': true});
      }
      return true;
    });
  }

  Future<bool> register(String uid) async {
    if (!supported || const bool.fromEnvironment('USE_EMULATORS')) {
      return true;
    }

    await start();
    final generation = ++_generation;
    _uid = uid;
    await _refresh?.cancel();

    final permission = await FirebaseMessaging.instance.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }
    if (_generation != generation ||
        FirebaseAuth.instance.currentUser?.uid != uid) {
      return true;
    }

    _refresh = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _save(uid, generation, token).catchError((Object error) {
        debugPrint(
          'Không cập nhật được thiết bị nhận thông báo: ${error.runtimeType}',
        );
      });
    });

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _save(uid, generation, token);
    return token != null;
  }

  Future<void> _save(String uid, int generation, String token) {
    final next = _saving.catchError((Object _) {}).then((_) async {
      if (generation != _generation ||
          FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      final key = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
      final ref = FirebaseFirestore.instance
          .collection('Admin')
          .doc(uid)
          .collection('ThietBi')
          .doc(key);
      final previous = _device;

      await ref.set({
        'token': token,
        'nenTang': 'android',
        'ngayCapNhat': FieldValue.serverTimestamp(),
      });

      if (generation != _generation ||
          FirebaseAuth.instance.currentUser?.uid != uid) {
        await ref.delete();
        return;
      }

      _device = ref;
      if (previous != null && previous.path != ref.path) {
        await previous.delete();
      }
    });

    _saving = next;
    return next;
  }

  Future<void> unregister() async {
    if (!supported || const bool.fromEnvironment('USE_EMULATORS')) return;
    if (_uid == null && _device == null) return;

    _generation++;
    _uid = null;
    opened.value = null;
    await _refresh?.cancel();
    _refresh = null;
    await _saving.catchError((Object _) {});

    final previousDevice = _device;
    _device = null;
    if (previousDevice != null) {
      try {
        await previousDevice.delete();
      } catch (error) {
        debugPrint(
          'Không xóa được bản ghi thiết bị khi đăng xuất: ${error.runtimeType}',
        );
      }
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint(
        'Không xóa được FCM token khi đăng xuất: ${error.runtimeType}',
      );
    }
  }

  void clearPending() => opened.value = null;

  bool forCurrentUser(Map<String, dynamic> data) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return currentUid != null &&
        currentUid == _uid &&
        data['maAdmin'] == currentUid;
  }
}
