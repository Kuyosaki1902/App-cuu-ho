import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrangThaiXacThucController extends ChangeNotifier {
  bool isRefreshing = false;

  String maHoSo = '#YTE-115-84920';
  String trangThaiText = 'Đang tiếp nhận';
  String thoiGianThamDinh = 'Dự kiến 48 giờ làm việc';
  String thoiGianConLai = 'Còn ~48h00m';

  final String userId;
  Timer? _timer;
  DateTime? thoiGianGuiYeuCau;
  StreamSubscription<DocumentSnapshot>? _hoSoSubscription;

  // Callback điều hướng
  Function()? onApproved;
  Function()? onRejected;

  TrangThaiXacThucController({required this.userId}) {
    maHoSo = userId;
    listenToTrangThaiHoSo();
  }

  /// 🟢 Lắng nghe thời gian thực thay đổi trạng thái từ Firestore
  void listenToTrangThaiHoSo() {
    _hoSoSubscription = FirebaseFirestore.instance
        .collection('HoSoCuuHoCoCCHN')
        .doc(userId)
        .snapshots()
        .listen((doc) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            String maTrangThai =
                data['maTrangThaiHoSo'] ?? 'cuuho_trangthai_tiepnhan';

            if (data['thoiGianOnline'] != null) {
              thoiGianGuiYeuCau = DateTime.tryParse(data['thoiGianOnline']);
            }

            // 🟢 Kiểm tra các mã trong collection TrangThai
            switch (maTrangThai) {
              case 'cuuho_trangthai_tiepnhan':
                trangThaiText = 'Đang tiếp nhận';
                break;

              case 'cuuho_trangthai_daduyet':
                trangThaiText = 'Đã phê duyệt';
                notifyListeners();
                // Tự động kích hoạt chuyển sang Màn hình chính Cứu hộ viên
                if (onApproved != null) onApproved!();
                return;

              case 'cuuho_trangthai_tuchoi':
                trangThaiText = 'Từ chối hồ sơ';
                notifyListeners();
                // Tự động kích hoạt chuyển sang Màn hình chính Người dùng
                if (onRejected != null) onRejected!();
                return;

              default:
                trangThaiText = 'Đang tiếp nhận';
            }

            notifyListeners();
            _startCountdownTimer();
          }
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
    _hoSoSubscription
        ?.cancel(); // Hủy đăng ký lắng nghe Firestore khi thoát màn hình
    super.dispose();
  }
}
