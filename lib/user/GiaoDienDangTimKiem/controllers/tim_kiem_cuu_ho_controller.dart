// lib/GiaoDienDangTimKiem/controllers/tim_kiem_cuu_ho_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/Models/chitietphancongcuuhomodel%20.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'dart:convert';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:cuhokhancap/gemini/gemini_service.dart';
import 'package:cuhokhancap/user/Models/chitietmotahientruongmodel.dart';
import 'package:cuhokhancap/user/Models/luuanhmodel.dart';
import 'package:cuhokhancap/user/Models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/Models/yeucaucuuhomodel.dart';

class _ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TimKiemCuuHoController {
  final FirebaseService _firebaseService = FirebaseService();
  final GeminiService _geminiService = GeminiService();
  int manualSelectedCount = 0;
  GoogleMapController? mapController;
  bool isLoading = true;
  Timer? _fallbackTimer;
  YeuCauCuuHoModel? yeuCauCuuHo;
  ChiTietMoTaHienTruongModel? chiTietMoTa;
  List<LuuAnhModel> danhSachAnhBase64 = [];

  Map<String, LatLng> initialRescuerLocations = {};
  LatLng currentDeviceLocation = const LatLng(10.7769, 106.6993);

  final Set<Circle> circles = {};
  final Set<Marker> markers = {};

  int currentScanStep = 0;
  final List<double> scanRadii = [1000, 3000, 5000];

  Timer? _radarPeriodicTimer;
  Timer? _secondsTimer;
  StreamSubscription<List<ChiTietPhanCongCuuHoModel>>? _phanCongSubscription;

  int elapsedSeconds = 0;
  List<Map<String, dynamic>> rescuerList = [];
  List<String> acceptedRescuerIds = [];
  Set<String> assignedRescuerIds = {};
  bool _isOverdueHandled = false;

  Map<String, dynamic>? aiAnalysisResult;

  String get formattedElapsedTime {
    int minutes = elapsedSeconds ~/ 60;
    int seconds = elapsedSeconds % 60;
    if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  bool _hasNavigated = false;
  // Lấy giới hạn số người cần cứu hộ
  int get limitCans => yeuCauCuuHo?.soNguoiCanCuuHo ?? 3;

  Future<void> initSearch(
    String maYeuCau,
    Function() onUpdate, {
    List<String>? danhSachChiDinh,
    Function(Map<String, LatLng>)? onRescuerAccepted,
  }) async {
    isLoading = true;
    _hasNavigated = false;
    _isOverdueHandled = false;

    assignedRescuerIds.clear();
    initialRescuerLocations.clear();
    acceptedRescuerIds.clear();
    rescuerList.clear();
    elapsedSeconds = 0;
    markers.clear();
    circles.clear();
    onUpdate();

    try {
      yeuCauCuuHo = await _firebaseService.getYeuCauCuuHoById(maYeuCau);

      if (yeuCauCuuHo != null) {
        yeuCauCuuHo!.danhSachPhanCongVien.clear();
        await _firebaseService.saveYeuCauCuuHo(yeuCauCuuHo!);
      }

      if (yeuCauCuuHo != null &&
          yeuCauCuuHo!.viDo != null &&
          yeuCauCuuHo!.kinhDo != null) {
        currentDeviceLocation = LatLng(
          yeuCauCuuHo!.viDo!,
          yeuCauCuuHo!.kinhDo!,
        );
      }

      moveToCurrentLocation();

      if (yeuCauCuuHo != null) {
        await _firebaseService.notifyConnectedRelatives(
          maNguoiYeuCau: yeuCauCuuHo!.maNguoiYeuCau,
          maYeuCau: maYeuCau,
          viDo: currentDeviceLocation.latitude,
          kinhDo: currentDeviceLocation.longitude,
        );
      }

      chiTietMoTa = await _firebaseService.getMoTaHienTruongById(maYeuCau);
      if (chiTietMoTa != null) {
        danhSachAnhBase64 = await _firebaseService.getImagesByMoTaId(
          chiTietMoTa!.maYeuCau,
        );

        if (yeuCauCuuHo?.maLoaiYeuCau != 'loaiyeucau_sos') {
          aiAnalysisResult = await _geminiService.analyzeSceneAndSuggestSkills(
            moTa: chiTietMoTa!,
            danhSachAnhBase64: danhSachAnhBase64,
          );
        }
      }

      await updateMapOverlays();
      _listenToPhanCongChanges(maYeuCau, onUpdate, onRescuerAccepted);

      if (yeuCauCuuHo?.maLoaiYeuCau == 'loaiyeucau_choncuuhovien' &&
          danhSachChiDinh != null &&
          danhSachChiDinh.isNotEmpty) {
        manualSelectedCount = danhSachChiDinh.length;
        List<NguoiDungModel> targetUsers = await _firebaseService.getUsersByIds(
          danhSachChiDinh,
        );
        double maxDistanceMeters = 1000.0;

        for (var user in targetUsers) {
          if (user.viDo != null && user.kinhDo != null) {
            double distance = Geolocator.distanceBetween(
              currentDeviceLocation.latitude,
              currentDeviceLocation.longitude,
              user.viDo!,
              user.kinhDo!,
            );
            if (distance > maxDistanceMeters) {
              maxDistanceMeters = distance;
            }
          }
        }

        if (maxDistanceMeters <= 1000) {
          currentScanStep = 0;
        } else if (maxDistanceMeters <= 3000) {
          currentScanStep = 1;
        } else {
          currentScanStep = 2;
        }

        await updateMapOverlays();
        await _assignToSpecificRescuers(maYeuCau, danhSachChiDinh, onUpdate);

        _fallbackTimer = Timer(const Duration(seconds: 60), () async {
          if (acceptedRescuerIds.isEmpty && !_isOverdueHandled) {
            debugPrint(
              '⏳ Quá 60s nhóm chỉ định không nhận đơn, tự động chuyển sang AI quét tự động!',
            );
            await _firebaseService.updateTinhTrangYeuCau(
              maYeuCau,
              'user_tinhtrang_chotiepnhan',
            );
            startAdaptiveAIRadar(maYeuCau, onUpdate);
          }
        });
      } else {
        startAdaptiveAIRadar(maYeuCau, onUpdate);
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo tìm kiếm cứu hộ: $e');
    } finally {
      isLoading = false; // Mọi thứ đã load xong
      onUpdate();

      _secondsTimer?.cancel();
      _secondsTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        elapsedSeconds++;

        // 🌟 Xác định mốc quá hạn tùy theo loại yêu cầu
        int maxTimeout =
            (yeuCauCuuHo?.maLoaiYeuCau == 'loaiyeucau_choncuuhovien')
            ? 120
            : 60;

        if (elapsedSeconds >= maxTimeout &&
            acceptedRescuerIds.isEmpty &&
            !_isOverdueHandled) {
          _isOverdueHandled = true;
          _stopAllTimers();

          debugPrint(
            '⏳ Đã quá ${maxTimeout}s không có ai nhận, chuyển sang QUÁ HẠN!',
          );
          await _firebaseService.updateTinhTrangYeuCau(
            maYeuCau,
            'user_tinhtrang_quahandieuphoi', // 🌟 Cập nhật trạng thái quá hạn điều phối
          );

          await _firebaseService.removeRequestFromRealtimeDB(maYeuCau);

          for (var maCuuHo in assignedRescuerIds) {
            await _firebaseService.updateUserOnlineStatus(
              userId: maCuuHo,
              isOnline: true,
              nhanCaCuuHo: false,
            );
          }
        }
        onUpdate();
      });
    }
  }

  Future<void> _assignToSpecificRescuers(
    String maYeuCau,
    List<String> targetIds,
    Function() onUpdate,
  ) async {
    List<NguoiDungModel> targetUsers = await _firebaseService.getUsersByIds(
      targetIds,
    );
    bool hasNewAssignment = false;

    for (var user in targetUsers) {
      if (user.viDo == null || user.kinhDo == null) {
        debugPrint('⚠️ Bỏ qua ${user.maNguoiDung} vì chưa có tọa độ GPS!');
        continue;
      }
      if (user.nhanCaCuuHo == true) {
        debugPrint(
          '⚠️ Bỏ qua ${user.maNguoiDung} vì đang kẹt ca (nhanCaCuuHo = true)',
        );
        continue;
      }

      double distanceMeters = Geolocator.distanceBetween(
        currentDeviceLocation.latitude,
        currentDeviceLocation.longitude,
        user.viDo!,
        user.kinhDo!,
      );

      assignedRescuerIds.add(user.maNguoiDung!);
      initialRescuerLocations[user.maNguoiDung!] = LatLng(
        user.viDo!,
        user.kinhDo!,
      );
      rescuerList.add({
        'user': user,
        'distanceKm': (distanceMeters / 1000).toStringAsFixed(1),
      });

      _addRescuerMarker(user, distanceMeters);
      await _createAssignmentRecord(maYeuCau, user.maNguoiDung!);
      hasNewAssignment = true;
    }

    if (hasNewAssignment && yeuCauCuuHo != null) {
      await _firebaseService.sendRequestToRealtimeDB(
        maNanNhan: yeuCauCuuHo!.maNguoiYeuCau,
        maYeuCau: maYeuCau,
        viDo: currentDeviceLocation.latitude,
        kinhDo: currentDeviceLocation.longitude,
        listCuuHoVienIds: assignedRescuerIds.toList(),
      );
    }
    onUpdate();
  }

  void _listenToPhanCongChanges(
    String maYeuCau,
    Function() onUpdate,
    Function(Map<String, LatLng>)? onRescuerAccepted,
  ) {
    _phanCongSubscription?.cancel();
    _phanCongSubscription = _firebaseService.streamPhanCongByYeuCau(maYeuCau).listen((
      phanCongList,
    ) async {
      for (var pc in phanCongList) {
        String? trangThaiCu =
            yeuCauCuuHo?.danhSachPhanCongVien[pc.maNguoiCuuHo];

        if (trangThaiCu != pc.maTrangThaiTiepNhan) {
          await _firebaseService.updateDanhSachPhanCongVien(
            maYeuCau: maYeuCau,
            maNguoiCuuHo: pc.maNguoiCuuHo,
            trangThai: pc.maTrangThaiTiepNhan,
          );

          Map<String, String> updatedMap = Map.from(
            yeuCauCuuHo?.danhSachPhanCongVien ?? {},
          );
          updatedMap[pc.maNguoiCuuHo] = pc.maTrangThaiTiepNhan;
          yeuCauCuuHo = yeuCauCuuHo?.copyWith(danhSachPhanCongVien: updatedMap);

          if (pc.maTrangThaiTiepNhan == 'cuuho_trangthai_phancong_tiepnhan') {
            int newSoLuong = (yeuCauCuuHo?.soNguoiCuuHo ?? 0) + 1;
            yeuCauCuuHo = yeuCauCuuHo?.copyWith(soNguoiCuuHo: newSoLuong);

            await FirebaseFirestore.instance
                .collection('YeuCauCuuHo')
                .doc(maYeuCau)
                .update({'soNguoiCuuHo': FieldValue.increment(1)});
          } else if (trangThaiCu == 'cuuho_trangthai_phancong_tiepnhan') {
            if ((yeuCauCuuHo?.soNguoiCuuHo ?? 0) > 0) {
              int newSoLuong = (yeuCauCuuHo!.soNguoiCuuHo) - 1;
              yeuCauCuuHo = yeuCauCuuHo?.copyWith(soNguoiCuuHo: newSoLuong);

              await FirebaseFirestore.instance
                  .collection('YeuCauCuuHo')
                  .doc(maYeuCau)
                  .update({'soNguoiCuuHo': FieldValue.increment(-1)});
            }
          }
        }

        if (pc.maTrangThaiTiepNhan == 'cuuho_trangthai_phancong_tiepnhan') {
          if (!acceptedRescuerIds.contains(pc.maNguoiCuuHo)) {
            acceptedRescuerIds.add(pc.maNguoiCuuHo);
          }
        } else if (trangThaiCu == 'cuuho_trangthai_phancong_tiepnhan') {
          acceptedRescuerIds.remove(pc.maNguoiCuuHo);
        }
      }

      // 🌟 Nếu có ít nhất 1 người nhận ca, cập nhật tình trạng yêu cầu thành user_tinhtrang_daphancong
      if (acceptedRescuerIds.isNotEmpty) {
        await _firebaseService.removeRequestFromRealtimeDB(maYeuCau);

        // Kiểm tra biến local để đảm bảo chỉ cập nhật Firebase 1 lần duy nhất
        if (yeuCauCuuHo?.maTinhTrangYeuCau != 'user_tinhtrang_daphancong') {
          await _firebaseService.updateTinhTrangYeuCau(
            maYeuCau,
            'user_tinhtrang_daphancong',
          );
          // Cập nhật ngay local để khóa chặn các lần gọi tiếp theo
          yeuCauCuuHo = yeuCauCuuHo?.copyWith(
            maTinhTrangYeuCau: 'user_tinhtrang_daphancong',
          );
        }

        if (!_hasNavigated && onRescuerAccepted != null) {
          _hasNavigated = true;
          onRescuerAccepted(initialRescuerLocations);
        }
      }

      // 🌟 Thay đổi điều kiện dừng: Số người tiếp nhận >= Số người cần cứu hộ
      if (acceptedRescuerIds.length >= limitCans) {
        _stopAllTimers();
        _phanCongSubscription?.cancel();
      }

      onUpdate();
    });
  }

  void startAdaptiveAIRadar(String maYeuCau, Function() onUpdate) async {
    if (_isOverdueHandled) return;
    currentScanStep = 0;
    await _executeAIScanAndAssign(maYeuCau, onUpdate);

    _radarPeriodicTimer?.cancel();
    _radarPeriodicTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      if (acceptedRescuerIds.isNotEmpty || _isOverdueHandled) {
        timer.cancel();
        return;
      }

      if (elapsedSeconds > 0 &&
          elapsedSeconds % 6 == 0 &&
          currentScanStep < scanRadii.length - 1) {
        currentScanStep++;
        await updateMapOverlays();
      }

      await _executeAIScanAndAssign(maYeuCau, onUpdate);
    });
  }

  Future<void> _executeAIScanAndAssign(
    String maYeuCau,
    Function() onUpdate,
  ) async {
    double maxDistanceMeters = scanRadii[currentScanStep];

    List<NguoiDungModel> onlineRescuers = await _firebaseService
        .getOnlineRescuers();
    if (onlineRescuers.isEmpty) return;

    List<Map<String, dynamic>> scoredRescuers = [];
    bool isSos = yeuCauCuuHo?.maLoaiYeuCau == 'loaiyeucau_sos';

    for (var rescuer in onlineRescuers) {
      if (rescuer.maNguoiDung == yeuCauCuuHo?.maNguoiYeuCau) continue;
      if (assignedRescuerIds.contains(rescuer.maNguoiDung)) continue;
      if (rescuer.viDo == null || rescuer.kinhDo == null) {
        debugPrint(
          '⚠️ Bỏ qua AI ${rescuer.maNguoiDung} vì chưa có tọa độ GPS!',
        );
        continue;
      }
      if (rescuer.nhanCaCuuHo == true) {
        debugPrint(
          '⚠️ Bỏ qua AI ${rescuer.maNguoiDung} vì đang kẹt ca (nhanCaCuuHo = true)',
        );
        continue;
      }

      double distanceMeters = Geolocator.distanceBetween(
        currentDeviceLocation.latitude,
        currentDeviceLocation.longitude,
        rescuer.viDo!,
        rescuer.kinhDo!,
      );

      if (distanceMeters <= maxDistanceMeters) {
        double score = 0.0;
        if (isSos) {
          score = 10000.0 - distanceMeters;
        } else {
          score = await _calculateAIScore(rescuer, distanceMeters);
        }

        scoredRescuers.add({
          'user': rescuer,
          'distanceMeters': distanceMeters,
          'score': score,
        });
      }
    }

    scoredRescuers.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    bool hasNewAssignment = false;

    for (var item in scoredRescuers) {
      if (acceptedRescuerIds.length >= limitCans) break;

      NguoiDungModel user = item['user'];
      String maNguoiCuuHo = user.maNguoiDung!;

      String? trangThaiCu = yeuCauCuuHo?.danhSachPhanCongVien[maNguoiCuuHo];
      if (trangThaiCu == 'cuuho_trangthai_phancong_tuchoi' ||
          trangThaiCu == 'tuchoi') {
        continue;
      }
      if (trangThaiCu != null && trangThaiCu.isNotEmpty) {
        continue;
      }

      double distanceKm = (item['distanceMeters'] as double) / 1000;

      assignedRescuerIds.add(maNguoiCuuHo);
      initialRescuerLocations[maNguoiCuuHo] = LatLng(user.viDo!, user.kinhDo!);
      rescuerList.add({
        'user': user,
        'distanceKm': distanceKm.toStringAsFixed(1),
      });

      _addRescuerMarker(user, (item['distanceMeters'] as double));
      await _createAssignmentRecord(maYeuCau, maNguoiCuuHo);
      hasNewAssignment = true;
    }

    if (hasNewAssignment && yeuCauCuuHo != null) {
      await _firebaseService.sendRequestToRealtimeDB(
        maNanNhan: yeuCauCuuHo!.maNguoiYeuCau,
        maYeuCau: maYeuCau,
        viDo: currentDeviceLocation.latitude,
        kinhDo: currentDeviceLocation.longitude,
        listCuuHoVienIds: assignedRescuerIds.toList(),
      );
    }

    onUpdate();
  }

  Future<double> _calculateAIScore(
    NguoiDungModel user,
    double distanceMeters,
  ) async {
    double score = 0.0;
    List<String> reqChuyenNganh = List<String>.from(
      aiAnalysisResult?['chuyenNganhYeuCau'] ?? [],
    );
    List<String> reqKyNang = List<String>.from(
      aiAnalysisResult?['kyNangYeuCau'] ?? [],
    );

    final hoSoCoCCHN = await _firebaseService.getHoSoCoCCHN(user.maNguoiDung!);
    if (hoSoCoCCHN != null) {
      String cn = hoSoCoCCHN.tenChuyenNganh.toLowerCase();
      for (var req in reqChuyenNganh) {
        if (cn.contains(req.toLowerCase())) {
          score += 8000.0;
        }
      }
    }

    List<String> userSkillIds = await _firebaseService.getSkillIdsByUserId(
      user.maNguoiDung!,
    );
    for (var skId in userSkillIds) {
      for (var req in reqKyNang) {
        if (skId.toLowerCase().contains(req.toLowerCase()) ||
            req.toLowerCase().contains(skId.toLowerCase())) {
          score += 5000.0;
        }
      }
    }

    score += (10000.0 - distanceMeters);
    return score;
  }

  Future<void> _createAssignmentRecord(
    String maYeuCau,
    String maNguoiCuuHo,
  ) async {
    try {
      String maPhanCong =
          'phancong_${maNguoiCuuHo}_${DateTime.now().millisecondsSinceEpoch}';

      final phanCong = ChiTietPhanCongCuuHoModel(
        maPhanCong: maPhanCong,
        maYeuCau: maYeuCau,
        loaiPhanCong: 'Hệ thống AI tự động',
        maNguoiCuuHo: maNguoiCuuHo,
        thoiGianGui: DateTime.now(),
        maLoaiPhanCong: 'phancong_hethongtudong',
        maTrangThaiTiepNhan: 'cuuho_trangthai_phancong_chotiepnhan',
      );

      await _firebaseService.createPhanCongTheoNgay(
        maNguoiCuuHo: maNguoiCuuHo,
        phanCong: phanCong,
      );

      await _firebaseService.updateDanhSachPhanCongVien(
        maYeuCau: maYeuCau,
        maNguoiCuuHo: maNguoiCuuHo,
        trangThai: 'cuuho_trangthai_phancong_chotiepnhan',
      );

      yeuCauCuuHo?.danhSachPhanCongVien[maNguoiCuuHo] =
          'cuuho_trangthai_phancong_chotiepnhan';
    } catch (e) {
      debugPrint('Lỗi tạo bản ghi phân công: $e');
    }
  }

  Future<void> fetchGPSLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentDeviceLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Lỗi GPS: $e');
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words.first[0]}'.toUpperCase();
  }

  Future<void> _addRescuerMarker(
    NguoiDungModel user,
    double distanceMeters,
  ) async {
    String? avatarData = await _firebaseService.getUserAvatarUrl(
      user.maNguoiDung!,
    );

    ImageProvider? avatarProvider;
    if (avatarData != null && avatarData.isNotEmpty) {
      if (avatarData.startsWith('http')) {
        avatarProvider = NetworkImage(avatarData);
      } else {
        String base64Str = avatarData.contains(',')
            ? avatarData.split(',').last
            : avatarData;
        try {
          avatarProvider = MemoryImage(base64Decode(base64Str));
        } catch (e) {
          debugPrint('Lỗi decode Base64 avatar: $e');
        }
      }
    }

    String distanceText = distanceMeters < 1000
        ? '${distanceMeters.toStringAsFixed(0)} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

    String initials = _getInitials(user.hoTen);

    Widget rescuerMarkerWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF006A55), width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: avatarProvider != null
                    ? Colors.white
                    : const Color(0xFF006A55),
                backgroundImage: avatarProvider,
                child: avatarProvider == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF006A55), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                distanceText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF006A55),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -1),
              child: ClipPath(
                clipper: _ArrowClipper(),
                child: Container(
                  width: 14,
                  height: 8,
                  color: const Color(0xFF006A55),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    BitmapDescriptor customIcon = await rescuerMarkerWidget
        .toBitmapDescriptor();

    markers.add(
      Marker(
        markerId: MarkerId('rescuer_${user.maNguoiDung}'),
        position: LatLng(user.viDo!, user.kinhDo!),
        icon: customIcon,
        anchor: const Offset(0.5, 1.0),
      ),
    );
  }

  Future<void> updateMapOverlays() async {
    circles.clear();
    markers.removeWhere((m) => m.markerId.value == 'current_device_marker');

    Widget victimMarkerWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC81E1E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_pin_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -1),
              child: ClipPath(
                clipper: _ArrowClipper(),
                child: Container(
                  width: 14,
                  height: 8,
                  color: const Color(0xFFC81E1E),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC81E1E),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  yeuCauCuuHo?.maLoaiYeuCau == 'loaiyeucau_sos'
                      ? 'SOS'
                      : 'Vị trí của bạn',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFFC81E1E),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    BitmapDescriptor victimIcon = await victimMarkerWidget.toBitmapDescriptor();

    markers.add(
      Marker(
        markerId: const MarkerId('current_device_marker'),
        position: currentDeviceLocation,
        icon: victimIcon,
        anchor: const Offset(0.5, 0.75),
      ),
    );

    circles.add(
      Circle(
        circleId: const CircleId('scan_radius_outer'),
        center: currentDeviceLocation,
        radius: scanRadii[currentScanStep],
        fillColor: const Color(0xFF006A55).withOpacity(0.12),
        strokeColor: const Color(0xFF006A55).withOpacity(0.4),
        strokeWidth: 2,
      ),
    );
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    moveToCurrentLocation();
  }

  Future<void> moveToCurrentLocation() async {
    if (mapController != null) {
      double currentZoom = await mapController!.getZoomLevel();
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentDeviceLocation, zoom: currentZoom),
        ),
      );
    }
  }

  void _stopAllTimers() {
    _radarPeriodicTimer?.cancel();
    _secondsTimer?.cancel();
    _fallbackTimer?.cancel();
  }

  void dispose() {
    _stopAllTimers();
    _phanCongSubscription?.cancel();
  }

  Future<void> cancelSearch(String maYeuCau) async {
    try {
      isLoading = true;
      _stopAllTimers();
      _phanCongSubscription?.cancel();

      String? maNanNhan = yeuCauCuuHo?.maNguoiYeuCau;
      if (maNanNhan != null) {
        await _firebaseService.removeEmergencyNotification(
          maNanNhan: maNanNhan,
        );
      }

      await _firebaseService.cancelRemainingAssignments(maYeuCau);
      await _firebaseService.updateTinhTrangYeuCau(
        maYeuCau,
        'user_tinhtrang_dahuy',
      );

      await _firebaseService.removeRequestFromRealtimeDB(maYeuCau);

      if (yeuCauCuuHo != null && yeuCauCuuHo!.danhSachPhanCongVien.isNotEmpty) {
        for (var maCuuHo in yeuCauCuuHo!.danhSachPhanCongVien.keys) {
          try {
            await _firebaseService.updateUserOnlineStatus(
              userId: maCuuHo,
              isOnline: true,
              nhanCaCuuHo: false,
            );
          } catch (e) {
            debugPrint('Lỗi cập nhật nhanCaCuuHo cho $maCuuHo: $e');
          }
        }
      }

      debugPrint(
        '✅ Đã hủy tìm kiếm, thu hồi đơn và reset trạng thái thành công!',
      );
    } catch (e) {
      debugPrint('❌ Lỗi khi hủy tìm kiếm: $e');
    } finally {
      isLoading = false;
    }
  }
}
