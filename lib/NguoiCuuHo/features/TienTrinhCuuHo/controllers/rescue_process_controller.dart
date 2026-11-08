import 'dart:async';
import 'dart:convert';
import 'package:cuhokhancap/NguoiCuuHo/Models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/NguoiCuuHo/Models/chitiettinnhanmodel.dart';
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
  ChiTietMoTaHienTruongModel? moTaHienTruongModel;
  List<ChiTietTinNhanModel> danhSachTinNhan = [];
  StreamSubscription<QuerySnapshot>? _tinNhanSubscription;
  final String currentDoctorId; // Thêm biến này để so sánh người gửi tin nhắn
  final String maYeuCau;

  RescueProcessController(this.currentDoctorId, this.maYeuCau) {
    _initTracking(currentDoctorId, maYeuCau);
    _startRescueTimer();
  }

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

  // Thông tin chi tiết hiện trường từ ChiTietMoTaHienTruong
  String moTaChiTiet = 'Đang tải...';
  List<String> trieuChung = [];
  String ghiAmUrl = '';
  String videoUrl = '';

  // Danh sách đội ngũ cùng tiếp nhận ca
  List<Map<String, dynamic>> teamMembers = [];
  final String googleApiKey = "AIzaSyDkN_9EJ9WUlWgap-TJV7ig93Yvqt1olps";
  Timer? _rescueTimer;
  int rescueElapsedSeconds = 0;

  List<LatLng> polylineCoordinates = [];
  String distanceText = '0m';
  String durationText = '0 phút';
  double currentSpeedKmH = 0.0;

  Future<void> _initTracking(String doctorId, String maYeuCau) async {
    await _fetchDoctorInfo(doctorId);
    await _fetchVictimInfo(maYeuCau);
    await _fetchTeamMembers(doctorId, maYeuCau);
    await _fetchChiTietMoTaHienTruong(maYeuCau);
    // 🟢 2. GỌI HÀM LẮNG NGHE TIN NHẮN
    _listenToTinNhan(maYeuCau);
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

        if (victimLocation.latitude != 0.0 && victimLocation.longitude != 0.0) {
          victimAddress = await getAddressFromLatLng(
            victimLocation.latitude,
            victimLocation.longitude,
          );
        } else {
          victimAddress = 'Không xác định được tọa độ vị trí';
        }

        notifyListeners();

        if (doctorLocation.latitude != 0.0) {
          fetchRealtimeRoute();
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải thông tin nạn nhân từ YeuCauCuuHo: $e');
    }
  }

  // 3. Lấy dữ liệu từ bảng ChiTietMoTaHienTruong
  Future<void> _fetchChiTietMoTaHienTruong(String maYeuCau) async {
    try {
      if (maYeuCau.isEmpty) return;
      DocumentSnapshot doc = await _firestore
          .collection('ChiTietMoTaHienTruong')
          .doc(maYeuCau)
          .get();

      if (doc.exists && doc.data() != null) {
        // Map dữ liệu vào Model
        moTaHienTruongModel = ChiTietMoTaHienTruongModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Đổ dữ liệu từ Model ra các biến cũ để UI không bị lỗi
        var ghiChuText = moTaHienTruongModel?.ghiChuText;
        if (ghiChuText != null && ghiChuText is Map) {
          moTaChiTiet = ghiChuText['moTaChiTiet'] ?? 'Chưa có mô tả chi tiết';
          var rawTrieuChung = ghiChuText['trieuChung'];
          if (rawTrieuChung is List) {
            trieuChung = rawTrieuChung.map((e) => e.toString()).toList();
          }
        }

        ghiAmUrl = moTaHienTruongModel?.ghiAmUrl ?? '';
        videoUrl = moTaHienTruongModel?.videoUrl ?? '';

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi tải ChiTietMoTaHienTruong: $e');
    }
  }

  // 🟢 4. HÀM LẮNG NGHE TIN NHẮN REALTIME (STREAM)
  void _listenToTinNhan(String maPhongChat) {
    _tinNhanSubscription?.cancel(); // Hủy stream cũ nếu có
    _tinNhanSubscription = _firestore
        .collection(
          'ChiTietTinNhan',
        ) // Thay bằng tên collection chứa tin nhắn của bạn
        .where('maPhongChat', isEqualTo: maPhongChat)
        .orderBy(
          'thoiGianGui',
          descending: true,
        ) // Sắp xếp giảm dần để tin mới nhất nằm dưới
        .snapshots()
        .listen((snapshot) {
          danhSachTinNhan = snapshot.docs.map((doc) {
            return ChiTietTinNhanModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
          notifyListeners();
        });
  }

  // 🟢 5. HÀM GỬI TIN NHẮN MỚI
  Future<void> guiTinNhan(String noiDung) async {
    if (noiDung.trim().isEmpty) return;
    try {
      final newMsg = ChiTietTinNhanModel(
        maTinNhan: '', // Sẽ được Firestore tự tạo id
        maPhongChat: maYeuCau,
        maNguoiGui: currentDoctorId,
        noiDung: noiDung,
        loaiTinNhan: 'text',
        thoiGianGui: DateTime.now(),
      );

      await _firestore.collection('ChiTietTinNhan').add(newMsg.toMap());
    } catch (e) {
      debugPrint('Lỗi gửi tin nhắn: $e');
    }
  }

  // 4. Gọi API OSRM lấy tuyến đường thực tế
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
          _capNhatThongKeHoSo('soLuongDaKhongNhan');
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi hủy ca: $e');
    }
  }

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
          .set({
            'maTrangThaiTiepNhan': 'cuuho_trangthai_phancong_hoanthanh',
          }, SetOptions(merge: true));

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
          _capNhatThongKeHoSo('soLuongCaHoanThanh');
        }
      }
      debugPrint('✅ Đã ép trạng thái ca thành HOÀN THÀNH thành công!');
    } catch (e) {
      debugPrint('❌ Lỗi khi hoàn thành ca cứu hộ: $e');
    }
  }

  Future<void> _capNhatThongKeHoSo(String fieldName) async {
    if (currentDoctorId.isEmpty) return;

    try {
      // 1. Kiểm tra maVaiTro trong bảng NguoiDung
      DocumentSnapshot userDoc = await _firestore
          .collection('NguoiDung')
          .doc(currentDoctorId)
          .get();

      if (!userDoc.exists || userDoc.data() == null) return;

      var userData = userDoc.data() as Map<String, dynamic>;
      String maVaiTro = (userData['maVaiTro'] ?? '').toString();

      // 2. Xác định Collection cần cập nhật
      String targetCollection = '';
      if (maVaiTro == 'vaitro_cuuhococc') {
        targetCollection = 'HoSoCuuHoCoCCHN';
      } else if (maVaiTro == 'vaitro_cuhochuacocc' ||
          maVaiTro == 'vaitro_cuhokhongcocc') {
        targetCollection = 'HoSoCuuHoKhongCCHN';
      }

      if (targetCollection.isNotEmpty) {
        // 3. Tăng trường chỉ định lên 1 đơn vị bằng FieldValue.increment(1)
        await _firestore.collection(targetCollection).doc(currentDoctorId).set({
          fieldName: FieldValue.increment(1),
        }, SetOptions(merge: true));

        debugPrint('✅ Đã tăng $fieldName trong $targetCollection thêm 1.');
      }
    } catch (e) {
      debugPrint('❌ Lỗi cập nhật chỉ số thống kê hồ sơ: $e');
    }
  }

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

  // 🌍 Sử dụng Google Geocoding API chính hãng, ổn định tại Việt Nam
  // controllers/emergency_alert_controller.dart

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    if (lat == 0.0 || lng == 0.0 || lat.isNaN || lng.isNaN) {
      return 'Đang định vị...';
    }

    // API Reverse Geocoding miễn phí từ Nominatim (OpenStreetMap)
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=vi',
    );

    try {
      // ⚠️ BẮT BUỘC phải truyền User-Agent để tuân thủ chính sách sử dụng của OSM
      final response = await http
          .get(
            url,
            headers: {
              'User-Agent': 'CuuHoKhanCapApp/1.0 (contact@cuhokhancap.com)',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null && data['display_name'] != null) {
          // Tối ưu hiển thị chuỗi địa chỉ cho gọn gàng (nếu cần)
          String fullAddress = data['display_name'];
          return fullAddress;
        }
      }
    } catch (e) {
      debugPrint('Lỗi Reverse Geocoding OSM: $e');
    }

    return 'Vị trí sự cố thực tế ($lat, $lng)';
  }

  Future<void> nextStep(String currentDoctorId, String maYeuCau) async {
    if (currentStep < 3) {
      currentStep++;
      notifyListeners();

      try {
        String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        String newStatus = '';

        if (currentStep == 1) {
          newStatus = 'cuuho_trangthai_phancong_daden';
        } else if (currentStep == 2) {
          newStatus = 'cuuho_trangthai_phancong_dangcuuho';
        } else if (currentStep == 3) {
          newStatus = 'cuuho_trangthai_phancong_hoanthanh';
        }

        Map<String, dynamic> updateData = {'currentStep': currentStep};

        if (newStatus.isNotEmpty) {
          updateData['maTrangThaiTiepNhan'] = newStatus;
        }

        await _firestore
            .collection('ChiTietPhanCongCuuHo')
            .doc(currentDoctorId)
            .collection('DanhSachNgay')
            .doc(todayStr)
            .collection('DanhSachPhanCong')
            .doc(maYeuCau)
            .set(updateData, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Lỗi cập nhật nextStep lên Firestore: $e');
      }
    }
  }

  void resetToNewCase() {
    currentStep = 0;
    rescueElapsedSeconds = 0;
    doctorLocation = const LatLng(0.0, 0.0);
    victimLocation = const LatLng(0.0, 0.0);
    polylineCoordinates.clear();
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
    _tinNhanSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _rescueTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}
