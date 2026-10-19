import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrangThaiXacThucController extends ChangeNotifier {
  bool isRefreshing = false;

  String maHoSo = '';
  String trangThaiText = 'Đang tiếp nhận';
  String thoiGianThamDinh = 'Dự kiến 48 giờ làm việc';
  String thoiGianConLai = 'Còn ~48h00m';

  final String userId;
  final bool isCoCCHN;

  Timer? _timer;
  DateTime? thoiGianGuiYeuCau;
  StreamSubscription<DocumentSnapshot>? _hoSoSubscription;

  // Callback điều hướng
  Function()? onApproved;
  Function()? onRejected;

  TrangThaiXacThucController({required this.userId, this.isCoCCHN = false}) {
    maHoSo = userId;
    listenToTrangThaiHoSo();
  }

  /// 🟢 Lắng nghe thời gian thực theo đúng Collection tương ứng
  void listenToTrangThaiHoSo() {
    isRefreshing = true;
    notifyListeners();

    String collectionName = isCoCCHN ? 'HoSoCuuHoCoCCHN' : 'HoSoCuuHoKhongCCHN';

    _hoSoSubscription?.cancel();

    // 🟢 Đọc trực tiếp từ Server để không bị dính dữ liệu cũ trong Cache
    FirebaseFirestore.instance
        .collection(collectionName)
        .doc(userId)
        .get(const GetOptions(source: Source.server)) // 👈 Ép lấy từ Server
        .then((doc) {
          isRefreshing = false;
          if (doc.exists && doc.data() != null) {
            final data = doc.data() as Map<String, dynamic>;
            String maTrangThai =
                (data['maTrangThaiHoSo'] ?? 'cuuho_trangthai_tiepnhan')
                    .toString()
                    .trim();

            debugPrint('📌 Dữ liệu THỰC TẾ từ Server: "$maTrangThai"');

            if (maTrangThai == 'cuuho_trangthai_daduyet') {
              trangThaiText = 'Đã phê duyệt';
              notifyListeners();
              if (onApproved != null) onApproved!();
            } else if (maTrangThai == 'cuuho_trangthai_tuchoi') {
              trangThaiText = 'Từ chối hồ sơ';
              notifyListeners();
              if (onRejected != null) onRejected!();
            } else {
              trangThaiText = 'Đang tiếp nhận';
              notifyListeners();
              _startCountdownTimer();
            }
          }
        })
        .catchError((e) {
          isRefreshing = false;
          notifyListeners();
          debugPrint('🔴 Lỗi tải dữ liệu từ Server: $e');
        });
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    thoiGianGuiYeuCau ??= DateTime.now();
    final DateTime targetTime = thoiGianGuiYeuCau!.add(
      const Duration(hours: 48),
    );

    _updateRemainingTime(targetTime);

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateRemainingTime(targetTime);
    });
  }

  void _updateRemainingTime(DateTime targetTime) {
    final now = DateTime.now();
    final difference = targetTime.difference(now);

    if (difference.isNegative || difference.inMinutes <= 0) {
      thoiGianConLai = 'Hết thời gian chờ (0h00m)';
      _timer?.cancel();
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);

      String hStr = hours.toString().padLeft(2, '0');
      String mStr = minutes.toString().padLeft(2, '0');

      thoiGianConLai = 'Còn ~${hStr}h${mStr}m';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hoSoSubscription?.cancel();
    super.dispose();
  }
}
