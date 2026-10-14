import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyAlertController extends ChangeNotifier {
  // Tọa độ Bác sĩ & Nạn nhân
  final LatLng myLocation = const LatLng(10.7326, 106.7180);
  final LatLng victimLocation = const LatLng(10.7350, 106.7230);

  // Danh sách các điểm tọa độ thực tế dọc con đường
  List<LatLng> polylineCoordinates = [];
  bool isLoadingRoute = true;

  // 🔴 Vui lòng bảo mật chuỗi API Key này
  final String googleApiKey = "AIzaSyDkN_9EJ9WUlWgap-TJV7ig93Yvqt1olps";

  Timer? _timer;
  int _remainingSeconds = 43;
  final int _totalSeconds = 60;

  int get remainingSeconds => _remainingSeconds;
  double get progressValue => _remainingSeconds / _totalSeconds;

  GoogleMapController? mapController;

  String doctorName = 'BS. Trần Minh Tuấn';
  String doctorRole = 'BÁC SĨ SƠ CỨU T1';
  String address = 'Hẻm 142/18 Huỳnh Tấn Phát, P. Tân Thuận';
  String victimName = 'Nguyễn Văn An';
  String victimPhone = '0903 *** 826';
  String distanceText = '650m';
  String bikeTime = '3 phút';
  String walkTime = '6 phút';

  EmergencyAlertController() {
    _startCountdown();
    fetchRealtimeRoute();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
      }
    });
  }

  String get formattedTimer {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}s';
  }

  // Hàm lấy đường đi thực tế từ Google Directions API
  Future<void> fetchRealtimeRoute() async {
    isLoadingRoute = true;
    notifyListeners();

    try {
      PolylinePoints polylinePoints = PolylinePoints(apiKey: googleApiKey);

      // 🟢 Truyền googleApiKey đúng vị trí trong PolylineRequest / apiKey tùy bản package
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(myLocation.latitude, myLocation.longitude),
          destination: PointLatLng(
            victimLocation.latitude,
            victimLocation.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        polylineCoordinates.clear();
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        // Nếu API trả về trống (do chưa bật Directions API trên Console), dùng danh sách mốc thực tế dự phòng
        _loadFallbackRoadWaypoints();
      }
    } catch (e) {
      debugPrint('Lỗi lấy tuyến đường API: $e');
      _loadFallbackRoadWaypoints();
    } finally {
      isLoadingRoute = false;
      notifyListeners();
    }
  }

  String rawVictimPhone =
      '0903826826'; // Số điện thoại dạng chuỗi thuần không dấu cách/ký tự đặc biệt

  Future<void> makePhoneCall() async {
    final Uri launchUri = Uri(scheme: 'tel', path: rawVictimPhone);

    try {
      // 🟢 Bắt buộc thêm mode: LaunchMode.externalApplication
      bool launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint('Không thể mở trình gọi điện');
      }
    } catch (e) {
      debugPrint('Lỗi khi gọi điện: $e');
    }
  }

  // 🟢 Tập hợp mốc đường uốn lượn thực tế theo lòng đường (Huỳnh Tấn Phát -> Nguyễn Văn Linh -> Hẻm 142)
  void _loadFallbackRoadWaypoints() {
    polylineCoordinates = [
      myLocation, // Bác sĩ ở đây
      const LatLng(10.7328, 106.7188), // Chạy dọc đường Huỳnh Tấn Phát
      const LatLng(10.7320, 106.7202), // Quẹo ở ngã tư Nguyễn Văn Linh
      const LatLng(10.7332, 106.7218), // Qua nút giao / Chân cầu
      const LatLng(10.7342, 106.7225), // Vào Hẻm 142
      victimLocation, // Nạn nhân (SOS)
    ];
  }

  // Mở ứng dụng Google Maps ngoài để dẫn đường GPS từng bước
  Future<void> startNavigation() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${myLocation.latitude},${myLocation.longitude}&destination=${victimLocation.latitude},${victimLocation.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Không thể mở bản đồ điều hướng');
    }
  }

  void playVictimVideo() {
    debugPrint('Mở video hiện trường');
  }

  @override
  void dispose() {
    _timer?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}
