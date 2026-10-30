import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:dart_geohash/dart_geohash.dart';

class EmergencyAlertController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<QuerySnapshot>? _assignmentSubscription;
  StreamSubscription<Position>? _positionStreamSubscription;

  LatLng myLocation = const LatLng(0.0, 0.0);
  LatLng victimLocation = const LatLng(0.0, 0.0);

  List<LatLng> polylineCoordinates = [];
  bool isLoadingRoute = true;

  final String googleApiKey = "AIzaSyDkN_9EJ9WUlWgap-TJV7ig93Yvqt1olps";

  // 🟢 1. ĐỔI THỜI GIAN ĐẾM NGƯỢC THÀNH 3 PHÚT (180 GIÂY)
  Timer? _timer;
  int _remainingSeconds = 180;
  final int _totalSeconds = 180;

  int get remainingSeconds => _remainingSeconds;
  double get progressValue => _remainingSeconds / _totalSeconds;

  GoogleMapController? mapController;

  String doctorName = 'Bác sĩ cứu hộ';
  String doctorRole = 'CỨU HỘ VIÊN PHẢN ỨNG NHANH';
  String address = 'Đang tải địa chỉ...';
  String victimName = 'Đang tải...';
  String victimPhone = '...';
  String distanceText = '0m';
  String motoTime = '0 p';
  String carTime = '0 p';
  String walkTime = '0 p';

  String currentDoctorId = '';
  String currentMaYeuCau = '';
  BuildContext? currentContext;

  String selectedTravelMode = 'cycling';

  EmergencyAlertController() {
    _startLocationTracking();
  }

  void changeTravelMode(String mode) {
    if (selectedTravelMode == mode) return;
    selectedTravelMode = mode;
    notifyListeners();
    fetchRealtimeRoute(shouldMoveCamera: false);
  }

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
        timeLimit: const Duration(seconds: 10),
      );
      myLocation = LatLng(currentPos.latitude, currentPos.longitude);
      notifyListeners();

      if (victimLocation.latitude != 0.0 && victimLocation.longitude != 0.0) {
        fetchRealtimeRoute();
      }
    } catch (e) {
      debugPrint('Lỗi lấy vị trí ban đầu của Cứu hộ viên: $e');
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            LatLng newLocation = LatLng(position.latitude, position.longitude);
            myLocation = newLocation;
            notifyListeners();

            if (victimLocation.latitude != 0.0 &&
                victimLocation.longitude != 0.0) {
              fetchRealtimeRoute(shouldMoveCamera: false);
            }
          },
        );
  }

  void setMapController(GoogleMapController controller) {
    mapController = controller;
    _moveCameraToFitPositions();
  }

  void listenForNewAssignment(
    String currentUserId,
    BuildContext context,
  ) async {
    _assignmentSubscription?.cancel();
    currentDoctorId = currentUserId;
    currentContext = context;

    await _fetchDoctorInfo(currentUserId);

    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

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

            for (var doc in snapshot.docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String trangThai = (data['maTrangThaiTiepNhan'] ?? '').toString();

              if (trangThai == 'cuuho_trangthai_phancong_chotiepnhan' ||
                  trangThai.isEmpty) {
                targetDoc = doc;
                foundMaYeuCau =
                    data.containsKey('maYeuCau') &&
                        (data['maYeuCau'] ?? '').toString().isNotEmpty
                    ? data['maYeuCau'].toString()
                    : doc.id;
                break;
              }
            }

            if (foundMaYeuCau.isNotEmpty) {
              currentMaYeuCau = foundMaYeuCau;
              await _playEmergencySound();
              await _fetchVictimRequestDetails(foundMaYeuCau);
              fetchRealtimeRoute();

              // 🟢 Bắt đầu đếm ngược 3 phút khi nhận ca thành công
              _startCountdown();
            }
          }
        });
  }

  // 🟢 2. BỘ ĐẾM NGƯỢC 3 PHÚT & XỬ LÝ KHI HẾT GIỜ TỰ ĐỘNG TỪ CHỐI
  void _startCountdown() {
    _timer?.cancel();
    _remainingSeconds = _totalSeconds; // Reset về 180 giây
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // HẾT 3 PHÚT KHÔNG THAO TÁC -> TỰ TỪ CHỐI & QUAY VỀ MÀN HÌNH CHÍNH
        _timer?.cancel();
        await stopEmergencySound();
        await _handleTimeoutReject();
      }
    });
  }

  // 🟢 3. XỬ LÝ HẾT 3 PHÚT: CẬP NHẬT TỪ CHỐI & BẬT NHANCA=TRUE TRÊN NGUOIDUNG
  Future<void> _handleTimeoutReject() async {
    if (currentDoctorId.isEmpty || currentMaYeuCau.isEmpty) return;

    try {
      String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // a. Cập nhật maTrangThaiTiepNhan = cuuho_trangthai_phancong_tuchoi
      await _firestore
          .collection('ChiTietPhanCongCuuHo')
          .doc(currentDoctorId)
          .collection('DanhSachNgay')
          .doc(todayStr)
          .collection('DanhSachPhanCong')
          .doc(currentMaYeuCau)
          .set({
            'maTrangThaiTiepNhan': 'cuuho_trangthai_phancong_tuchoi',
          }, SetOptions(merge: true));

      // b. Cập nhật nhanCaCuuHo = true trên bảng NguoiDung
      await _firestore.collection('NguoiDung').doc(currentDoctorId).set({
        'nhanCaCuuHo': true,
      }, SetOptions(merge: true));

      debugPrint('Đã tự động từ chối ca do hết 3 phút');

      // c. Tự động chuyển về màn hình chính
      if (currentContext != null && Navigator.canPop(currentContext!)) {
        Navigator.pop(currentContext!);
      }
    } catch (e) {
      debugPrint('Lỗi xử lý tự động từ chối hết giờ: $e');
    }
  }

  // 🟢 4. KHI BẤM NÚT DẪN ĐƯỜNG: CẬP NHẬT CHẤP NHẬN TIEPNHAN
  Future<void> startNavigation() async {
    await stopEmergencySound();
    _timer?.cancel();

    // Cập nhật trạng thái Firestore nếu có ca phân công
    if (currentDoctorId.isNotEmpty && currentMaYeuCau.isNotEmpty) {
      try {
        String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

        // a. Cập nhật maTrangThaiTiepNhan = cuuho_trangthai_phancong_tiepnhan
        await _firestore
            .collection('ChiTietPhanCongCuuHo')
            .doc(currentDoctorId)
            .collection('DanhSachNgay')
            .doc(todayStr)
            .collection('DanhSachPhanCong')
            .doc(currentMaYeuCau)
            .set({
              'maTrangThaiTiepNhan': 'cuuho_trangthai_phancong_tiepnhan',
            }, SetOptions(merge: true));

        // b. Cập nhật nhanCaCuuHo = false trong bảng NguoiDung (Đang trong ca)
        await _firestore.collection('NguoiDung').doc(currentDoctorId).set({
          'nhanCaCuuHo': false,
        }, SetOptions(merge: true));

        debugPrint('Đã cập nhật tiếp nhận ca thành công');
      } catch (e) {
        debugPrint('Lỗi cập nhật tiếp nhận ca: $e');
      }
    }

    // Mở Google Maps điều hướng ngoài
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${myLocation.latitude},${myLocation.longitude}&destination=${victimLocation.latitude},${victimLocation.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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

        if (myLocation.latitude == 0.0) {
          String? doctorGeohash = data['geoHash'] ?? data['geohash'];
          if (doctorGeohash != null && doctorGeohash.isNotEmpty) {
            myLocation = _getLatLngFromGeohash(doctorGeohash);
          } else if (data['viDo'] != null && data['kinhDo'] != null) {
            myLocation = LatLng(
              (data['viDo'] as num).toDouble(),
              (data['kinhDo'] as num).toDouble(),
            );
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi đọc thông tin cứu hộ viên: $e');
    }
  }

  Future<void> _fetchVictimRequestDetails(String maYeuCau) async {
    try {
      DocumentSnapshot yeuCauDoc = await _firestore
          .collection('YeuCauCuuHo')
          .doc(maYeuCau)
          .get();

      if (yeuCauDoc.exists && yeuCauDoc.data() != null) {
        var yeuCauData = yeuCauDoc.data() as Map<String, dynamic>;

        String? ycGeohash = yeuCauData['geoHash'] ?? yeuCauData['geohash'];
        if (ycGeohash != null && ycGeohash.isNotEmpty) {
          victimLocation = _getLatLngFromGeohash(ycGeohash);
        } else if (yeuCauData['viDo'] != null && yeuCauData['kinhDo'] != null) {
          victimLocation = LatLng(
            (yeuCauData['viDo'] as num).toDouble(),
            (yeuCauData['kinhDo'] as num).toDouble(),
          );
        }

        String maNguoiYeuCau =
            (yeuCauData['maNguoiYeuCau'] ?? yeuCauData['maNguoiDung'] ?? '')
                .toString();

        if (maNguoiYeuCau.isNotEmpty) {
          DocumentSnapshot userDoc = await _firestore
              .collection('NguoiDung')
              .doc(maNguoiYeuCau)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            var userData = userDoc.data() as Map<String, dynamic>;
            victimName = userData['hoTen'] ?? 'Nạn nhân khẩn cấp';
            victimPhone = userData['soDienThoai'] ?? 'Chưa cập nhật';

            if (victimLocation.latitude == 0.0) {
              String? userGeohash = userData['geoHash'] ?? userData['geohash'];
              if (userGeohash != null && userGeohash.isNotEmpty) {
                victimLocation = _getLatLngFromGeohash(userGeohash);
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

        if (victimLocation.latitude != 0.0 && victimLocation.longitude != 0.0) {
          address = await getAddressFromLatLng(
            victimLocation.latitude,
            victimLocation.longitude,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Lỗi đọc bảng YeuCauCuuHo & NguoiDung: $e');
    }
  }

  LatLng _getLatLngFromGeohash(String geohashStr) {
    try {
      GeoHash geoHash = GeoHash(geohashStr);
      return LatLng(geoHash.latitude(), geoHash.longitude());
    } catch (e) {
      debugPrint('Lỗi giải mã Geohash: $e');
      return const LatLng(0.0, 0.0);
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

  Future<void> fetchRealtimeRoute({bool shouldMoveCamera = true}) async {
    if (myLocation.latitude == 0.0 || victimLocation.latitude == 0.0) {
      return;
    }

    isLoadingRoute = true;
    notifyListeners();

    try {
      final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/$selectedTravelMode/${myLocation.longitude},${myLocation.latitude};${victimLocation.longitude},${victimLocation.latitude}?overview=full&geometries=polyline',
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

          if (decodedPoints.isNotEmpty) {
            polylineCoordinates.clear();
            for (var point in decodedPoints) {
              polylineCoordinates.add(LatLng(point.latitude, point.longitude));
            }
          } else {
            _loadFallbackRoadWaypoints();
          }

          double distanceMeters = (route['distance'] as num).toDouble();
          double durationSeconds = (route['duration'] as num).toDouble();

          distanceText = distanceMeters >= 1000
              ? '${(distanceMeters / 1000).toStringAsFixed(1)}km'
              : '${distanceMeters.toInt()}m';

          int carMinutes = (durationSeconds / 30).ceil();
          carTime = '$carMinutes p';

          int bikeMinutes = (durationSeconds / 40).ceil();
          motoTime = '$bikeMinutes p';

          int walkMinutes = (distanceMeters / 75).ceil();
          walkTime = '$walkMinutes p';
        } else {
          _loadFallbackRoadWaypoints();
        }
      } else {
        _loadFallbackRoadWaypoints();
      }
    } catch (e) {
      debugPrint('Lỗi gọi API OSRM: $e');
      _loadFallbackRoadWaypoints();
    } finally {
      isLoadingRoute = false;
      notifyListeners();
      if (shouldMoveCamera) {
        _moveCameraToFitPositions();
      }
    }
  }

  void _moveCameraToFitPositions() {
    if (mapController == null) return;

    if (myLocation.latitude != 0.0 && victimLocation.latitude != 0.0) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              myLocation.latitude < victimLocation.latitude
                  ? myLocation.latitude
                  : victimLocation.latitude,
              myLocation.longitude < victimLocation.longitude
                  ? myLocation.longitude
                  : victimLocation.longitude,
            ),
            northeast: LatLng(
              myLocation.latitude > victimLocation.latitude
                  ? myLocation.latitude
                  : victimLocation.latitude,
              myLocation.longitude > victimLocation.longitude
                  ? myLocation.longitude
                  : victimLocation.longitude,
            ),
          ),
          80.0,
        ),
      );
    } else if (victimLocation.latitude != 0.0) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(victimLocation, 16.0),
      );
    }
  }

  void _loadFallbackRoadWaypoints() {
    polylineCoordinates = [myLocation, victimLocation];
  }

  Future<void> _playEmergencySound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/emergency_alarm.mp3'));
    } catch (e) {
      debugPrint('Lỗi phát âm thanh chuông báo: $e');
    }
  }

  Future<void> stopEmergencySound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Lỗi tắt âm thanh: $e');
    }
  }

  // 🟢 Định dạng hiển thị phút : giây (Ví dụ: 02 : 59s)
  String get formattedTimer {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}s';
  }

  Future<void> makePhoneCall() async {
    final Uri launchUri = Uri(scheme: 'tel', path: victimPhone);
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Lỗi gọi điện: $e');
    }
  }

  void playVictimVideo() {
    debugPrint('Mở video hiện trường');
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _assignmentSubscription?.cancel();
    stopEmergencySound();
    _timer?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}
