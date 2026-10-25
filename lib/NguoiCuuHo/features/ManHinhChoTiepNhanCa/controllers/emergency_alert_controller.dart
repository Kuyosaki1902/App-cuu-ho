import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart'; // 🟢 Import thư viện âm thanh

class EmergencyAlertController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer(); // 🟢 Khởi tạo AudioPlayer

  StreamSubscription<QuerySnapshot>? _assignmentSubscription;

  // Tọa độ Bác sĩ & Nạn nhân
  LatLng myLocation = const LatLng(10.7326, 106.7180);
  LatLng victimLocation = const LatLng(10.7350, 106.7230);

  List<LatLng> polylineCoordinates = [];
  bool isLoadingRoute = true;
  final String googleApiKey = "AIzaSyDkN_9EJ9WUlWgap-TJV7ig93Yvqt1olps";

  Timer? _timer;
  int _remainingSeconds = 60;
  final int _totalSeconds = 60;

  int get remainingSeconds => _remainingSeconds;
  double get progressValue => _remainingSeconds / _totalSeconds;

  GoogleMapController? mapController;

  String doctorName = 'BS. Trần Minh Tuấn';
  String doctorRole = 'BÁC SĨ SƠ CỨU T1';
  String address = 'Đang tải địa chỉ...';
  String victimName = 'Đang tải...';
  String victimPhone = '...';
  String distanceText = '0m';
  String bikeTime = '0 phút';
  String walkTime = '0 phút';

  EmergencyAlertController() {
    _startCountdown();
  }

  // 🟢 LẮNG NGHE PHÂN CÔNG THEO NÚT: maNguoiDung -> DanhSachNgay (yyyy-MM-dd) -> DanhSachPhanCong (maYeuCau)
  // 🟢 LẮNG NGHE PHÂN CÔNG: Lọc theo ngày hôm nay -> Duyệt toàn bộ maYeuCau kiểm tra field maTrangThaiTiepNhan
  void listenForNewAssignment(String currentUserId, BuildContext context) {
    _assignmentSubscription?.cancel();

    // 1. Lấy ngày hiện tại theo định dạng yyyy-MM-dd
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 2. Lắng nghe toàn bộ tài liệu trong sub-collection DanhSachPhanCong của ngày hôm nay
    _assignmentSubscription = _firestore
        .collection('ChiTietPhanCongCuuHo')
        .doc(currentUserId)
        .collection('DanhSachNgay')
        .doc(todayStr)
        .collection('DanhSachPhanCong')
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            DocumentSnapshot? targetDoc;
            String foundMaYeuCau = '';

            // 🟢 Duyệt qua từng tài liệu maYeuCau trong sub-collection
            for (var doc in snapshot.docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String trangThai = (data['maTrangThaiTiepNhan'] ?? '').toString();

              // Kiểm tra xem field maTrangThaiTiepNhan có bằng 'cuuho_trangthai_chophanhoi' không
              if (trangThai == 'cuuho_trangthai_chophanhoi') {
                targetDoc = doc;
                foundMaYeuCau =
                    data.containsKey('maYeuCau') &&
                        (data['maYeuCau'] ?? '').toString().isNotEmpty
                    ? data['maYeuCau'].toString()
                    : doc.id; // Lấy ID tài liệu (chính là maYeuCau) nếu field trống
                break; // Tìm thấy ca đầu tiên đang chờ phản hồi thì dừng vòng lặp
              }
            }

            // 🟢 Nếu tìm thấy yêu cầu ở trạng thái chờ phản hồi
            if (targetDoc != null && foundMaYeuCau.isNotEmpty) {
              // 1. Phát chuông cảnh báo khẩn cấp
              await _playEmergencySound();

              // 2. Đọc thông tin nạn nhân từ bảng YeuCauCuuHo
              await _fetchVictimRequestDetails(foundMaYeuCau);

              // 3. Cập nhật đường đi thực tế trên Google Maps
              fetchRealtimeRoute();
            }
          }
        });
  }

  // 🟢 2. ĐỌC DỮ LIỆU CHUẨN TỪ BẢNG YeuCauCuuHo VÀ NguoiDung
  Future<void> _fetchVictimRequestDetails(String maYeuCau) async {
    try {
      DocumentSnapshot yeuCauDoc = await _firestore
          .collection('YeuCauCuuHo')
          .doc(maYeuCau)
          .get();

      if (yeuCauDoc.exists && yeuCauDoc.data() != null) {
        var data = yeuCauDoc.data() as Map<String, dynamic>;

        // 1. Đọc tọa độ GPS sự cố
        if (data['viDo'] != null && data['kinhDo'] != null) {
          victimLocation = LatLng(
            (data['viDo'] as num).toDouble(),
            (data['kinhDo'] as num).toDouble(),
          );
        }

        // 2. Lấy mã người yêu cầu để truy vấn bảng NguoiDung lấy Tên & SĐT
        String maNguoiYeuCau = data['maNguoiYeuCau'] ?? '';
        if (maNguoiYeuCau.isNotEmpty) {
          DocumentSnapshot userDoc = await _firestore
              .collection('NguoiDung')
              .doc(maNguoiYeuCau)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            var userData = userDoc.data() as Map<String, dynamic>;
            victimName = userData['hoTen'] ?? 'Nạn nhân khẩn cấp';
            victimPhone = userData['soDienThoai'] ?? 'Chưa cập nhật';
          }
        }

        // 3. Đọc số người cần cứu hộ và mức độ khẩn cấp (nếu cần hiển thị thêm)
        int soNguoi = (data['soNguoiCanCuuHo'] as num?)?.toInt() ?? 1;
        int mucDo = (data['mucDoKhanCap'] as num?)?.toInt() ?? 1;

        debugPrint(
          'Tải xong YeuCauCuuHo: $maYeuCau | Số người: $soNguoi | Mức độ: $mucDo',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi đọc bảng YeuCauCuuHo: $e');
    }
  }

  // 🟢 HÀM PHÁT CHUÔNG BÁO LẶP LẠI
  Future<void> _playEmergencySound() async {
    try {
      await _audioPlayer.setReleaseMode(
        ReleaseMode.loop,
      ); // Lặp liên tục chuông báo
      await _audioPlayer.play(AssetSource('sounds/emergency_alarm.mp3'));
    } catch (e) {
      debugPrint('Lỗi phát âm thanh chuông báo: $e');
    }
  }

  // 🟢 HÀM TẮT CHUÔNG BÁO (GỌI KHI BẤM DẪN ĐƯỜNG HOẶC CHẤP NHẬN)
  Future<void> stopEmergencySound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Lỗi tắt âm thanh: $e');
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        stopEmergencySound(); // Tắt chuông khi hết thời gian chờ
        _timer?.cancel();
      }
    });
  }

  String get formattedTimer {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}s';
  }

  Future<void> fetchRealtimeRoute() async {
    isLoadingRoute = true;
    notifyListeners();

    try {
      PolylinePoints polylinePoints = PolylinePoints(apiKey: googleApiKey);

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

  Future<void> makePhoneCall() async {
    final Uri launchUri = Uri(scheme: 'tel', path: victimPhone);
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Lỗi gọi điện: $e');
    }
  }

  void _loadFallbackRoadWaypoints() {
    polylineCoordinates = [
      myLocation,
      const LatLng(10.7328, 106.7188),
      const LatLng(10.7320, 106.7202),
      const LatLng(10.7332, 106.7218),
      const LatLng(10.7342, 106.7225),
      victimLocation,
    ];
  }

  Future<void> startNavigation() async {
    await stopEmergencySound(); // Tắt âm thanh khi bấm dẫn đường

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${myLocation.latitude},${myLocation.longitude}&destination=${victimLocation.latitude},${victimLocation.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void playVictimVideo() {
    debugPrint('Mở video hiện trường');
  }

  @override
  void dispose() {
    _assignmentSubscription?.cancel();
    stopEmergencySound();
    _timer?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}
