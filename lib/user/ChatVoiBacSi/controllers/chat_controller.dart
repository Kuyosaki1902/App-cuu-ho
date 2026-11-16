// lib/user/ChatVoiBacSi/controllers/chat_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/user/Models/chitiettinnhanmodel.dart';

class ChatController {
  final String maPhongChat; // maYeuCau
  final String maNguoiCuuHo;
  String currentUserId = '';
  final double victimLat;
  final double victimLng;

  final TextEditingController msgController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FirebaseService _fbService = FirebaseService();

  StreamSubscription? _locationSub;

  final ValueNotifier<String> distanceNotifier = ValueNotifier('-- km');
  final ValueNotifier<String> estimatedTimeNotifier = ValueNotifier(
    '-- phút nữa tới',
  );
  final ValueNotifier<String> arrivalTimeNotifier = ValueNotifier('--:--');
  final ValueNotifier<String> addressNotifier = ValueNotifier(
    'Đang tải địa điểm hẹn...',
  );

  final Map<String, Map<String, String>> userCache = {};

  ChatController({
    required this.maPhongChat,
    required this.maNguoiCuuHo,
    required this.victimLat,
    required this.victimLng,
  }) {
    _initCurrentUserId();
    _initRescuerLocationTracking();
    _loadAddress();
  }

  Future<void> _initCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('maNguoiDung_daLuu') ?? '';
  }

  Future<void> _loadAddress() async {
    String addr = await _fbService.getAddressFromLatLng(victimLat, victimLng);
    addressNotifier.value = addr;
  }

  void _initRescuerLocationTracking() {
    _locationSub = FirebaseFirestore.instance
        .collection('NguoiDung')
        .doc(maNguoiCuuHo)
        .snapshots()
        .listen((docSnap) async {
          if (docSnap.exists && docSnap.data() != null) {
            double curLat = docSnap.data()?['viDo'] ?? 0.0;
            double curLng = docSnap.data()?['kinhDo'] ?? 0.0;

            if (curLat != 0.0 && curLng != 0.0) {
              await _fetchOSRMData(curLat, curLng);
            }
          }
        });
  }

  Future<void> _fetchOSRMData(double curLat, double curLng) async {
    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/$curLng,$curLat;$victimLng,$victimLat?overview=false',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          double distanceMeters = route['distance'].toDouble();
          double durationSeconds = route['duration'].toDouble();

          double distanceKm = distanceMeters / 1000;
          distanceNotifier.value = "${distanceKm.toStringAsFixed(1)} km";

          int minutes = (durationSeconds / 60).round();
          if (minutes < 1) minutes = 1;
          estimatedTimeNotifier.value = "$minutes phút nữa tới";

          DateTime arrival = DateTime.now().add(
            Duration(seconds: durationSeconds.toInt()),
          );
          arrivalTimeNotifier.value =
              "${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}";
        }
      }
    } catch (e) {
      debugPrint("Lỗi OSRM trong Chat: $e");
    }
  }

  Future<Map<String, String>> getSenderInfo(String userId) async {
    if (userCache.containsKey(userId)) {
      return userCache[userId]!;
    }
    final info = await _fbService.getUserInfoForChat(userId);
    userCache[userId] = info;
    return info;
  }

  Stream<List<ChiTietTinNhanModel>> getMessagesStream() {
    return _fbService.streamDanhSachTinNhan(maPhongChat);
  }

  Future<void> sendMessage() async {
    final text = msgController.text.trim();
    if (text.isEmpty) return;

    if (currentUserId.isEmpty) {
      await _initCurrentUserId();
    }

    msgController.clear();

    final tinNhan = ChiTietTinNhanModel(
      maTinNhan: '',
      maPhongChat: maPhongChat,
      maNguoiGui: currentUserId,
      noiDung: text,
      loaiTinNhan: 'text',
      thoiGianGui: DateTime.now(),
    );

    await _fbService.guiTinNhanMoi(maPhongChat, tinNhan);
    scrollToBottom();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String formatTime(DateTime time) {
    String formatted = DateFormat('hh:mm a').format(time);
    return formatted.replaceAll('AM', 'SA').replaceAll('PM', 'CH');
  }

  void dispose() {
    _locationSub?.cancel();
    msgController.dispose();
    scrollController.dispose();
    distanceNotifier.dispose();
    estimatedTimeNotifier.dispose();
    arrivalTimeNotifier.dispose();
    addressNotifier.dispose();
  }
}
