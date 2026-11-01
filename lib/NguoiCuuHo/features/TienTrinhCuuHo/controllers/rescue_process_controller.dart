import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:intl/intl.dart';

class RescueProcessController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int currentStep = 0;
  GoogleMapController? mapController;

  // 📍 Tọa độ thực tế ban đầu
  LatLng doctorLocation = const LatLng(0.0, 0.0);
  LatLng victimLocation = const LatLng(0.0, 0.0);

  StreamSubscription<Position>? _positionStreamSubscription;

  // Thông tin cứu hộ viên
  String doctorName = 'Đang tải...';
  String doctorRole = 'CỨU HỘ VIÊN PHẢN ỨNG NHANH';
  String doctorPhone = '';
  String? doctorAvatarUrl;

  // Thông tin nạn nhân
  String victimName = 'Đang tải...';
  String victimPhone = '';
  String victimAddress = 'Đang tải địa chỉ...';

  // Danh sách đội ngũ cùng tiếp nhận ca
  List<Map<String, dynamic>> teamMembers = [];

  final String googleApiKey = "AIzaSyDkN_9EJ9WUlWgap-TJV7ig93Yvqt1olps";

  Timer? _rescueTimer;
  int rescueElapsedSeconds = 0; // Tự động reset về 0 khi khởi tạo ca mới

  List<LatLng> polylineCoordinates = [];
  String distanceText = '0m';
  String durationText = '0 phút';
  double currentSpeedKmH = 0.0;

  RescueProcessController(String doctorId, String maYeuCau) {
    _initTracking(doctorId, maYeuCau);
    _startRescueTimer();
  }

  Future<void> _initTracking(String doctorId, String maYeuCau) async {
    await _fetchDoctorInfo(doctorId);
    await _fetchVictimInfo(maYeuCau);
    await _fetchTeamMembers(doctorId, maYeuCau);
    _startLocationTracking();
  }

  // 1. Lấy vị trí thực tế của cứu hộ viên (GPS Realtime)
  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position currentPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      doctorLocation = LatLng(currentPos.latitude, currentPos.longitude);
      currentSpeedKmH = (currentPos.speed * 3.6).clamp(0.0, 120.0);
      notifyListeners();

      if (victimLocation.latitude != 0.0) {
        fetchRealtimeRoute();
      }
    } catch (e) {
      debugPrint('Lỗi lấy GPS cứu hộ viên: $e');
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            doctorLocation = LatLng(position.latitude, position.longitude);
            currentSpeedKmH = (position.speed * 3.6).clamp(0.0, 120.0);
            notifyListeners();

            if (victimLocation.latitude != 0.0) {
              fetchRealtimeRoute();
            }
          },
        );
  }

  // 2. Lấy vị trí thực tế của nạn nhân từ Firestore
  Future<void> _fetchVictimInfo(String maYeuCau) async {
    try {
      if (maYeuCau.isEmpty) return;
      DocumentSnapshot ycDoc = await _firestore
          .collection('YeuCauCuuHo')
          .doc(maYeuCau)
          .get();

      if (ycDoc.exists && ycDoc.data() != null) {
        var data = ycDoc.data() as Map<String, dynamic>;

        String? geohash = data['geoHash'] ?? data['geohash'];
        if (geohash != null && geohash.isNotEmpty) {
          GeoHash geo = GeoHash(geohash);
          victimLocation = LatLng(geo.latitude(), geo.longitude());
        } else if (data['viDo'] != null && data['kinhDo'] != null) {
          victimLocation = LatLng(
            (data['viDo'] as num).toDouble(),
            (data['kinhDo'] as num).toDouble(),
          );
        }

        String maNguoiYeuCau =
            (data['maNguoiYeuCau'] ?? data['maNguoiDung'] ?? '').toString();
        if (maNguoiYeuCau.isNotEmpty) {
          DocumentSnapshot userDoc = await _firestore
              .collection('NguoiDung')
              .doc(maNguoiYeuCau)
              .get();
          if (userDoc.exists && userDoc.data() != null) {
            var userData = userDoc.data() as Map<String, dynamic>;
            victimName = userData['hoTen'] ?? 'Nạn nhân';
            victimPhone = userData['soDienThoai'] ?? '';

            if (victimLocation.latitude == 0.0) {
              String? uGeohash = userData['geoHash'] ?? userData['geohash'];
              if (uGeohash != null && uGeohash.isNotEmpty) {
                GeoHash geo = GeoHash(uGeohash);
                victimLocation = LatLng(geo.latitude(), geo.longitude());
              } else if (userData['viDo'] != null &&
                  userData['kinhDo'] != null) {
                victimLocation = LatLng(
                  (userData['viDo'] as num).toDouble(),
                  (userData['kinhDo'] as num).toDouble(),
                );
              }
            }
          }
        }

        notifyListeners();

        if (victimLocation.latitude != 0.0) {
          victimAddress = await getAddressFromLatLng(
            victimLocation.latitude,
            victimLocation.longitude,
          );
          notifyListeners();
        }

        if (doctorLocation.latitude != 0.0) {
          fetchRealtimeRoute();
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải thông tin nạn nhân: $e');
    }
  }

  // 3. Gọi API OSRM lấy tuyến đường thực tế
  Future<void> fetchRealtimeRoute() async {
    if (doctorLocation.latitude == 0.0 || victimLocation.latitude == 0.0)
      return;

    try {
      final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/${doctorLocation.longitude},${doctorLocation.latitude};${victimLocation.longitude},${victimLocation.latitude}?overview=full&geometries=polyline',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          var route = data['routes'][0];
          String encodedPolyline = route['geometry'];
          List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(
            encodedPolyline,
          );

          polylineCoordinates.clear();
          for (var point in decodedPoints) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }

          double distanceMeters = (route['distance'] as num).toDouble();
          double durationSeconds = (route['duration'] as num).toDouble();

          distanceText = distanceMeters >= 1000
              ? '${(distanceMeters / 1000).toStringAsFixed(1)}km'
              : '${distanceMeters.toInt()}m';

          int minutes = (durationSeconds / 60).ceil();
          durationText = 'Dự kiến đến trong ~$minutes phút';
          notifyListeners();

          _fitMapBounds();
        }
      }
    } catch (e) {
      debugPrint('Lỗi lấy tuyến đường OSRM: $e');
      polylineCoordinates = [doctorLocation, victimLocation];
    }
  }

  void _fitMapBounds() {
    if (mapController == null) return;
    if (doctorLocation.latitude == 0.0 || victimLocation.latitude == 0.0)
      return;

    double minLat = doctorLocation.latitude < victimLocation.latitude
        ? doctorLocation.latitude
        : victimLocation.latitude;
    double maxLat = doctorLocation.latitude > victimLocation.latitude
        ? doctorLocation.latitude
        : victimLocation.latitude;
    double minLng = doctorLocation.longitude < victimLocation.longitude
        ? doctorLocation.longitude
        : victimLocation.longitude;
    double maxLng = doctorLocation.longitude > victimLocation.longitude
        ? doctorLocation.longitude
        : victimLocation.longitude;

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        70.0,
      ),
    );
  }

  // 🟢 Giải phóng trạng thái trực (đặt nhanCaCuuHo = false) khi bấm Sẵn sàng ca mới ở Step 4
  Future<void> releaseRescueDuty(String currentDoctorId) async {
    try {
      await _firestore.collection('NguoiDung').doc(currentDoctorId).update({
        'nhanCaCuuHo': false,
      });
      debugPrint('Đã kết thúc ca, đặt nhanCaCuuHo = false thành công.');
    } catch (e) {
      debugPrint('Lỗi khi giải phóng trạng thái trực: $e');
    }
  }

  Future<void> _fetchDoctorInfo(String doctorId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('NguoiDung')
          .doc(doctorId)
          .get();
      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        doctorName = data['hoTen'] ?? 'Bác sĩ cứu hộ';
        doctorPhone = data['soDienThoai'] ?? '';
        doctorAvatarUrl = data['anhDaiDien'] ?? data['avatar'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi tải thông tin bác sĩ: $e');
    }
  }

  Future<void> _fetchTeamMembers(
    String currentDoctorId,
    String maYeuCau,
  ) async {
    try {
      if (maYeuCau.isEmpty) return;
      DocumentSnapshot ycDoc = await _firestore
          .collection('YeuCauCuuHo')
          .doc(maYeuCau)
          .get();

      if (ycDoc.exists && ycDoc.data() != null) {
        var data = ycDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> phanCongVienMap =
            data['danhSachPhanCongVien'] ?? {};

        List<Map<String, dynamic>> tempTeam = [];

        for (String doctorId in phanCongVienMap.keys) {
          if (doctorId == currentDoctorId) continue;
          DocumentSnapshot userDoc = await _firestore
              .collection('NguoiDung')
              .doc(doctorId)
              .get();
          if (userDoc.exists && userDoc.data() != null) {
            var userData = userDoc.data() as Map<String, dynamic>;
            tempTeam.add({
              'id': doctorId,
              'name': userData['hoTen'] ?? 'Cứu hộ viên',
              'role': userData['chuyenKhoa'] ?? userData['vaiTro'] ?? '',
              'phone': userData['soDienThoai'] ?? '',
              'status':
                  phanCongVienMap[doctorId] ==
                      'cuuho_trangthai_phancong_tiepnhan'
                  ? 'Đã nhận ca'
                  : 'Đang chờ',
            });
          }
        }

        teamMembers = tempTeam;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách đội ngũ: $e');
    }
  }

  // Cập nhật trạng thái hủy ca
  Future<void> cancelAssignment(String currentDoctorId, String maYeuCau) async {
    try {
      String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _firestore
          .collection('ChiTietPhanCongCuuHo')
          .doc(currentDoctorId)
          .collection('DanhSachNgay')
          .doc(todayStr)
          .collection('DanhSachPhanCong')
          .doc(maYeuCau)
          .update({'maTrangThaiTiepNhan': 'cuuho_trangthai_phancong_dahuy'});

      DocumentReference ycRef = _firestore
          .collection('YeuCauCuuHo')
          .doc(maYeuCau);
      DocumentSnapshot ycDoc = await ycRef.get();
      if (ycDoc.exists && ycDoc.data() != null) {
        var data = ycDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> phanCongMap = data['danhSachPhanCongVien'] ?? {};
        if (phanCongMap.containsKey(currentDoctorId)) {
          phanCongMap[currentDoctorId] = 'cuuho_trangthai_phancong_dahuy';
          await ycRef.update({'danhSachPhanCongVien': phanCongMap});
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi hủy ca: $e');
    }
  }

  // Cập nhật trạng thái hoàn thành ca ở Step 3 (không set nhanCaCuuHo ở đây nữa)
  Future<void> completeRescueMission(
    String currentDoctorId,
    String maYeuCau,
  ) async {
    try {
      String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _firestore
          .collection('ChiTietPhanCongCuuHo')
          .doc(currentDoctorId)
          .collection('DanhSachNgay')
          .doc(todayStr)
          .collection('DanhSachPhanCong')
          .doc(maYeuCau)
          .update({
            'maTrangThaiTiepNhan': 'cuuho_trangthai_phancong_hoanthanh',
          });

      DocumentReference ycRef = _firestore
          .collection('YeuCauCuuHo')
          .doc(maYeuCau);
      DocumentSnapshot ycDoc = await ycRef.get();
      if (ycDoc.exists && ycDoc.data() != null) {
        var data = ycDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> phanCongMap = data['danhSachPhanCongVien'] ?? {};
        if (phanCongMap.containsKey(currentDoctorId)) {
          phanCongMap[currentDoctorId] = 'cuuho_trangthai_phancong_hoanthanh';
          await ycRef.update({'danhSachPhanCongVien': phanCongMap});
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi hoàn thành ca cứu hộ: $e');
    }
  }

  // 🟢 Lưu hồ sơ cứu hộ vào collection HoSoCuuHo theo cấu trúc yêu cầu
  Future<void> saveRescueRecordToFirestore(
    String currentDoctorId,
    String maYeuCau,
  ) async {
    try {
      DocumentSnapshot ycDoc = await _firestore
          .collection('YeuCauCuuHo')
          .doc(maYeuCau)
          .get();

      String maNanNhanVal = '';
      List<String> danhSachCuuHoVienIds = [currentDoctorId];

      if (ycDoc.exists && ycDoc.data() != null) {
        var data = ycDoc.data() as Map<String, dynamic>;
        maNanNhanVal = (data['maNguoiYeuCau'] ?? data['maNguoiDung'] ?? '')
            .toString();

        Map<String, dynamic> phanCongMap = data['danhSachPhanCongVien'] ?? {};
        danhSachCuuHoVienIds = phanCongMap.keys.toList();
        if (!danhSachCuuHoVienIds.contains(currentDoctorId)) {
          danhSachCuuHoVienIds.add(currentDoctorId);
        }
      }

      Map<String, dynamic> hoSoData = {
        'maCuuHo': maYeuCau,
        'maNanNhan': maNanNhanVal,
        'DanhSachCuuHoVien': danhSachCuuHoVienIds,
        'bacSiPhuTrach': doctorName,
        'maBacSiPhuTrach': currentDoctorId,
        'tenNanNhan': victimName,
        'soDienThoaiNanNhan': victimPhone,
        'diaChiSuCo': victimAddress,
        'tongThoianGiay': rescueElapsedSeconds,
        'tongThoiGianHienThi': formattedRescueTime,
        'donViTiepNhan': 'Khoa Cấp Cứu - TT 115 TP.HCM',
        'benhVienChuyenTuyen': 'Bệnh viện ND 115 (Ưu tiên 1)',
        'tomTatXuTri': [
          'Nẹp cố định cẳng chân phải',
          'Băng ép cầm máu vô khuẩn',
          'Giảm đau & Ổn định tư thế',
          'Chuyển hồ sơ y tế số hóa',
        ],
        'sinhHieu': {
          'huyetAp': '120/80',
          'spo2': '98%',
          'trangThai': 'Ổn định',
        },
        'xacThucKySo': {
          'maeSign': '115-OK-$maYeuCau',
          'thoiGianKhopLenh': FieldValue.serverTimestamp(),
          'trangThai': 'HỢP LỆ',
        },
        'thoiGianHoanThanh': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('HoSoCuuHo')
          .doc(maYeuCau)
          .set(hoSoData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Lỗi khi lưu HoSoCuuHo: $e');
    }
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    if (lat == 0.0 || lng == 0.0 || lat.isNaN || lng.isNaN) {
      return 'Đang định vị...';
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey&language=vi',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' &&
            data['results'] != null &&
            (data['results'] as List).isNotEmpty) {
          return data['results'][0]['formatted_address'] ??
              'Vị trí sự cố thực tế';
        }
      }
    } catch (e) {
      debugPrint('Lỗi HTTP Geocoding API: $e');
    }
    return 'Vị trí sự cố thực tế';
  }

  void nextStep() {
    if (currentStep < 3) {
      currentStep++;
      notifyListeners();
    }
  }

  void resetToNewCase() {
    currentStep = 0;
    rescueElapsedSeconds = 0;
    notifyListeners();
  }

  void _startRescueTimer() {
    _rescueTimer?.cancel();
    _rescueTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentStep == 2) {
        rescueElapsedSeconds++;
        notifyListeners();
      }
    });
  }

  String get formattedRescueTime {
    int minutes = rescueElapsedSeconds ~/ 60;
    int seconds = rescueElapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> makePhoneCall(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone.replaceAll(RegExp(r'\s+'), ''),
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Lỗi khi gọi điện: $e');
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _rescueTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}
