import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RescueProcessController extends ChangeNotifier {
  // 🟢 Quản lý bước hiện tại (0: Di chuyển, 1: Đến nơi, 2: Cứu nạn, 3: Hoàn tất)
  int currentStep = 0;

  // Controller quản lý camera Google Maps
  GoogleMapController? mapController;

  // 📍 Tọa độ hiện trường Bác sĩ & Nạn nhân
  final LatLng doctorLocation = const LatLng(10.7326, 106.7180);
  final LatLng victimLocation = const LatLng(10.7350, 106.7230);

  // Thông tin bác sĩ & nạn nhân hiển thị
  String doctorName = 'BS. Trần Minh Tuấn';
  String victimName = 'Nguyễn Văn An';
  String victimPhone = '0903826826';
  String victimAddress = 'Hẻm 142/18 Huỳnh Tấn Phát, P. Tân Thuận Tây, Q.7';

  // ⏱️ Timer cho Bước 3: Cứu nạn (Thời gian can thiệp trực tiếp)
  Timer? _rescueTimer;
  int rescueElapsedSeconds = 504; // Mô phỏng khởi tạo 08:24s như thiết kế

  RescueProcessController() {
    _startRescueTimer();
  }

  // --- HÀM CHUYỂN BƯỚC TIẾN TRÌNH ---
  void nextStep() {
    if (currentStep < 3) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void setStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex <= 3) {
      currentStep = stepIndex;
      notifyListeners();
    }
  }

  void resetToNewCase() {
    currentStep = 0;
    rescueElapsedSeconds = 0;
    notifyListeners();
  }

  // --- LOGIC ĐẾM THỜI GIAN CAN THIỆP SƠ CỨU (BƯỚC 3) ---
  void _startRescueTimer() {
    _rescueTimer?.cancel();
    _rescueTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Chỉ đếm giờ khi đang ở Bước 3 (index == 2)
      if (currentStep == 2) {
        rescueElapsedSeconds++;
        notifyListeners();
      }
    });
  }

  // Định dạng hiển thị phút : giây (VD: 08 : 24)
  String get formattedRescueTime {
    int minutes = rescueElapsedSeconds ~/ 60;
    int seconds = rescueElapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}';
  }

  // --- HÀM ĐIỀU HƯỚNG BẢN ĐỒ ---
  void animateToDoctorLocation() {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(doctorLocation, 16.0),
      );
    }
  }

  void animateToVictimLocation() {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(victimLocation, 16.0),
      );
    }
  }

  // --- HÀM KÍCH HOẠT GỌI ĐIỆN NATIVE ---
  Future<void> makePhoneCall(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone.replaceAll(RegExp(r'\s+'), ''), // Xóa khoảng trắng
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Không thể mở ứng dụng gọi điện cho số: $phone');
      }
    } catch (e) {
      debugPrint('Lỗi khi gọi điện: $e');
    }
  }

  @override
  void dispose() {
    _rescueTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}
