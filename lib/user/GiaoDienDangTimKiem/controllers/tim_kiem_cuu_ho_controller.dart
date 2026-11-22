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
import 'package:cuhokhancap/user/Models/videohuongdanmodel.dart'
    show boDauTiengViet;
import 'package:cuhokhancap/user/GiaoDienDangTimKiem/service/yeu_cau_storage_service.dart';

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

class _RescuerScoreInfo {
  final String chuyenNganh;
  final List<String> skillIds;
  _RescuerScoreInfo(this.chuyenNganh, this.skillIds);
}

class _Catalogs {
  final Map<String, String> kyNang; // mã -> tên
  final List<String> chuyenNganh;
  _Catalogs(this.kyNang, this.chuyenNganh);
}

class TimKiemCuuHoController {
  final FirebaseService _firebaseService = FirebaseService();
  final GeminiService _geminiService = GeminiService();
  int manualSelectedCount = 0;
  GoogleMapController? mapController;
  bool isLoading = true;
  YeuCauCuuHoModel? yeuCauCuuHo;
  ChiTietMoTaHienTruongModel? chiTietMoTa;
  List<LuuAnhModel> danhSachAnhBase64 = [];
  bool _disposed = false;
  Map<String, LatLng> initialRescuerLocations = {};
  LatLng currentDeviceLocation = const LatLng(10.7769, 106.6993);

  final Set<Circle> circles = {};
  final Set<Marker> markers = {};

  int currentScanStep = 0;
  final List<double> scanRadii = [1000, 3000, 5000];

  Timer? _secondsTimer;

  // 🌟 Bộ đếm duy nhất: mọi thứ (đồng hồ, bán kính, quét, quá hạn) đều bám vào elapsedSeconds
  final Stopwatch _stopwatch = Stopwatch();
  int _baseSeconds = 0;
  int _aiStartSecond =
      0; // 0 = quét ngay; 60 = chờ nhóm chỉ định 60s rồi mới quét
  bool _setupDone = false;
  bool _switchedToAI = false;
  bool _tickBusy = false;
  bool _isScanning = false;
  StreamSubscription<List<ChiTietPhanCongCuuHoModel>>? _phanCongSubscription;

  int elapsedSeconds = 0;
  List<Map<String, dynamic>> rescuerList = [];
  List<String> acceptedRescuerIds = [];
  Set<String> assignedRescuerIds = {};

  // 🌟 Tách riêng người chọn tay và người do AI quét thêm
  Set<String> manualSelectedIds = {};
  Set<String> aiFoundRescuerIds = {};
  int get aiFoundCount => aiFoundRescuerIds.length;

  bool _isOverdueHandled = false;

  Map<String, dynamic>? aiAnalysisResult;

  final Map<String, _RescuerScoreInfo> _scoreInfoCache = {};
  _Catalogs? _catalogCache;

  String get formattedElapsedTime {
    int minutes = elapsedSeconds ~/ 60;
    int seconds = elapsedSeconds % 60;
    if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  bool _hasNavigated = false;
  int get limitCans => yeuCauCuuHo?.soNguoiCanCuuHo ?? 3;

  Future<_Catalogs> _loadCatalogs() async {
    if (_catalogCache != null) return _catalogCache!;

    final kyNang = <String, String>{};
    final chuyenNganh = <String>{};

    try {
      final dm = await _firebaseService.getDanhMucKyNang();
      for (final k in dm) {
        final ma = k['ma'] ?? '';
        if (ma.isNotEmpty) kyNang[ma] = k['ten'] ?? ma;
      }
    } catch (e) {
      debugPrint('Không đọc được danh mục kỹ năng: $e');
    }

    try {
      final snap = await _firebaseService.getHoSoCoCCHNSnapshot();
      for (final d in snap.docs) {
        final t = (d.data()['tenChuyenNganh'] ?? '').toString().trim();
        if (t.isNotEmpty) chuyenNganh.add(t);
      }
    } catch (e) {
      debugPrint('Không đọc được danh mục chuyên ngành: $e');
    }

    return _catalogCache = _Catalogs(kyNang, chuyenNganh.toList());
  }

  void _runGeminiInBackground(String maYeuCau) async {
    try {
      final moTa = chiTietMoTa;
      if (moTa == null) return;

      final catalogs = await _loadCatalogs();

      final anh = await _firebaseService
          .getImagesByMoTaId(moTa.maYeuCau)
          .timeout(const Duration(seconds: 6));
      danhSachAnhBase64 = anh;

      final result = await _geminiService
          .analyzeSceneAndSuggestSkills(
            moTa: moTa,
            danhSachAnhBase64: anh,
            kyNangHopLe: catalogs.kyNang,
            chuyenNganhHopLe: catalogs.chuyenNganh,
          )
          .timeout(const Duration(seconds: 25));

      if (_disposed || _isOverdueHandled) return;

      final geminiCn = _asStringList(result['chuyenNganhYeuCau']);
      final geminiKn = _asStringList(result['kyNangYeuCau']);
      final local = aiAnalysisResult;
      aiAnalysisResult = {
        'trieuChung': result['trieuChung'] ?? local?['trieuChung'] ?? '',
        'chuyenNganhYeuCau': geminiCn.isNotEmpty
            ? geminiCn
            : _asStringList(local?['chuyenNganhYeuCau']),
        'kyNangYeuCau': geminiKn.isNotEmpty
            ? geminiKn
            : _asStringList(local?['kyNangYeuCau']),
      };
    } catch (e) {
      debugPrint('Gemini chậm/lỗi, giữ kết quả cục bộ: $e');
    }
  }

  Map<String, dynamic> _localAnalyze(String text) {
    final t = boDauTiengViet(text);
    final chuyenNganh = <String>{};
    final kyNang = <String>{};

    void match(
      List<String> keys, {
      List<String> cn = const [],
      List<String> kn = const [],
    }) {
      if (keys.any(t.contains)) {
        chuyenNganh.addAll(cn);
        kyNang.addAll(kn);
      }
    }

    match(
      ['ngung tim', 'ngung tho', 'bat tinh', 'khong tho', 'ngat xiu'],
      cn: ['hồi sức', 'tim mạch'],
      kn: ['kn_cpr'],
    );
    match(
      ['chay mau', 'xuat huyet', 'vet thuong', 'bi cat', 'bi dam'],
      cn: ['ngoại khoa'],
      kn: ['kn_bang_bo'],
    );
    match(
      ['gay xuong', 'gay chan', 'gay tay', 'trat khop', 'te nga', 'tai nan'],
      cn: ['chấn thương chỉnh hình', 'ngoại khoa'],
      kn: ['kn_co_dinh', 'kn_bang_bo'],
    );
    match(
      ['bi bong', 'bong lua', 'bong nuoc', 'bong hoa chat'],
      kn: ['kn_bong'],
    );
    match(
      ['hoc di vat', 'nghen', 'sac nuoc', 'sac thuc an', 'mac xuong'],
      cn: ['hồi sức'],
      kn: ['kn_di_vat'],
    );
    match(
      ['duoi nuoc', 'chet duoi', 'ngop nuoc'],
      cn: ['hồi sức'],
      kn: ['kn_duoi_nuoc', 'kn_cpr'],
    );
    match(
      ['dau nguc', 'dot quy', 'nhoi mau co tim', 'dau tim', 'benh tim'],
      cn: ['tim mạch'],
    );
    match(['kho tho', 'ngat tho'], cn: ['hồi sức']);

    return {
      'trieuChung': text,
      'chuyenNganhYeuCau': chuyenNganh.toList(),
      'kyNangYeuCau': kyNang.toList(),
    };
  }

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
    manualSelectedIds.clear();
    aiFoundRescuerIds.clear();
    manualSelectedCount = 0;
    initialRescuerLocations.clear();
    acceptedRescuerIds.clear();
    rescuerList.clear();
    elapsedSeconds = 0;
    currentScanStep = 0;
    _baseSeconds = 0;
    _aiStartSecond = 0;
    _setupDone = false;
    _switchedToAI = false;
    _tickBusy = false;
    _isScanning = false;
    markers.clear();
    circles.clear();
    onUpdate();

    try {
      // 1. Lưu mã yêu cầu vào bộ nhớ máy
      await YeuCauStorageService.saveActiveRequest(maYeuCau);
      yeuCauCuuHo = await _firebaseService.getYeuCauCuuHoById(maYeuCau);

      // Lấy tọa độ nạn nhân từ đơn trước để tính khoảng cách khôi phục chính xác
      if (yeuCauCuuHo != null &&
          yeuCauCuuHo!.viDo != null &&
          yeuCauCuuHo!.kinhDo != null) {
        currentDeviceLocation = LatLng(
          yeuCauCuuHo!.viDo!,
          yeuCauCuuHo!.kinhDo!,
        );
      }

      moveToCurrentLocation();

      // 2. Xác định danh sách người được chọn thủ công gốc:
      // - Nếu có truyền danhSachChiDinh (lần đầu từ màn Chọn cứu hộ viên) -> lưu vào cache.
      // - Nếu không truyền (mọi lần vào lại sau) -> đọc từ cache.
      List<String> savedManualIds =
          await YeuCauStorageService.getManualSelectedIds(maYeuCau);
      final bool isFirstManualAssign =
          savedManualIds.isEmpty &&
          danhSachChiDinh != null &&
          danhSachChiDinh.isNotEmpty;

      if (isFirstManualAssign) {
        savedManualIds = List<String>.from(danhSachChiDinh);
        await YeuCauStorageService.saveManualSelectedIds(
          maYeuCau,
          savedManualIds,
        );
      }
      manualSelectedIds = savedManualIds.toSet();
      manualSelectedCount = manualSelectedIds.length;

      // 3. Phục hồi danh sách đã phân công từ Firestore (nếu có)
      if (yeuCauCuuHo != null && yeuCauCuuHo!.danhSachPhanCongVien.isNotEmpty) {
        List<String> assignedIds = yeuCauCuuHo!.danhSachPhanCongVien.keys
            .toList();
        List<NguoiDungModel> existingUsers = await _firebaseService
            .getUsersByIds(assignedIds);

        for (var user in existingUsers) {
          final uid = user.maNguoiDung;
          if (uid == null) continue;
          String status = yeuCauCuuHo!.danhSachPhanCongVien[uid]!;

          // Bỏ qua người đã từ chối hoặc bị hủy
          if (status != 'cuuho_trangthai_phancong_tuchoi' &&
              status != 'cuuho_trangthai_phancong_dahuy') {
            assignedRescuerIds.add(uid);

            // Ai không nằm trong danh sách chọn tay gốc -> chính là người AI đã quét được
            if (!manualSelectedIds.contains(uid)) {
              aiFoundRescuerIds.add(uid);
            }

            if (status == 'cuuho_trangthai_phancong_tiepnhan' ||
                status == 'cuuho_trangthai_phancong_daden' ||
                status == 'cuuho_trangthai_phancong_dangcuuho' ||
                status == 'cuuho_trangthai_phancong_hoanthanh') {
              acceptedRescuerIds.add(uid);
            }

            if (user.viDo != null && user.kinhDo != null) {
              initialRescuerLocations[uid] = LatLng(user.viDo!, user.kinhDo!);
              double distanceMeters = Geolocator.distanceBetween(
                currentDeviceLocation.latitude,
                currentDeviceLocation.longitude,
                user.viDo!,
                user.kinhDo!,
              );

              rescuerList.add({
                'user': user,
                'distanceKm': (distanceMeters / 1000).toStringAsFixed(1),
              });
              await _addRescuerMarker(user, distanceMeters);
            }
          }
        }
        onUpdate();
      }

      // 4. Phục hồi thời gian đã quét từ trước (Nếu app bị đóng mở lại / quay lại từ màn Theo dõi)
      int? savedSeconds = await YeuCauStorageService.getElapsedSeconds(
        maYeuCau,
      );
      if (savedSeconds != null && savedSeconds > 0) {
        _baseSeconds = savedSeconds;
        elapsedSeconds = savedSeconds;
        debugPrint('🔄 Phục hồi phiên tìm kiếm cũ: $elapsedSeconds s');
      }

      if (yeuCauCuuHo != null) {
        await _firebaseService.notifyConnectedRelatives(
          maNguoiYeuCau: yeuCauCuuHo!.maNguoiYeuCau,
          maYeuCau: maYeuCau,
          viDo: currentDeviceLocation.latitude,
          kinhDo: currentDeviceLocation.longitude,
        );
      }

      chiTietMoTa = await _firebaseService.getMoTaHienTruongById(maYeuCau);
      if (chiTietMoTa != null &&
          yeuCauCuuHo?.maLoaiYeuCau != 'loaiyeucau_sos') {
        final g = chiTietMoTa!.ghiChuText;
        final text = g is Map
            ? '${(g['trieuChung'] ?? []).join(' ')} ${g['moTaChiTiet'] ?? ''}'
            : (g?.toString() ?? '');
        aiAnalysisResult = _localAnalyze(text);
        _runGeminiInBackground(maYeuCau);
      }

      // 5. Xử lý chế độ chọn cứu hộ viên (chỉ phân công lần đầu, vào lại chỉ khôi phục)
      if (yeuCauCuuHo?.maLoaiYeuCau == 'loaiyeucau_choncuuhovien') {
        _aiStartSecond = 60;

        if (manualSelectedIds.isNotEmpty) {
          List<NguoiDungModel> targetUsers = await _firebaseService
              .getUsersByIds(manualSelectedIds.toList());
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

          if (elapsedSeconds >= _aiStartSecond) {
            currentScanStep = _stepForElapsed(elapsedSeconds);
          } else if (maxDistanceMeters <= 1000) {
            currentScanStep = 0;
          } else if (maxDistanceMeters <= 3000) {
            currentScanStep = 1;
          } else {
            currentScanStep = 2;
          }

          if (isFirstManualAssign) {
            await _assignToSpecificRescuers(
              maYeuCau,
              manualSelectedIds.toList(),
              onUpdate,
            );
          }
        }
      } else {
        currentScanStep = _stepForElapsed(elapsedSeconds);
      }

      await updateMapOverlays();
      _listenToPhanCongChanges(maYeuCau, onUpdate, onRescuerAccepted);
    } catch (e) {
      debugPrint('Lỗi khởi tạo tìm kiếm cứu hộ: $e');
    } finally {
      isLoading = false;
      onUpdate();
      if (!_disposed) {
        _setupDone = true;
        _startTicker(maYeuCau, onUpdate);
      }
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
      if (user.viDo == null || user.kinhDo == null) continue;
      if (user.nhanCaCuuHo == true) continue;
      if (assignedRescuerIds.contains(user.maNguoiDung)) continue;

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

      await _addRescuerMarker(user, distanceMeters);
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
    _phanCongSubscription = _firebaseService
        .streamPhanCongByYeuCau(maYeuCau)
        .listen((phanCongList) async {
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
              yeuCauCuuHo = yeuCauCuuHo?.copyWith(
                danhSachPhanCongVien: updatedMap,
              );

              if (pc.maTrangThaiTiepNhan ==
                  'cuuho_trangthai_phancong_tiepnhan') {
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

          if (acceptedRescuerIds.isNotEmpty) {
            await _firebaseService.removeRequestFromRealtimeDB(maYeuCau);

            if (yeuCauCuuHo?.maTinhTrangYeuCau != 'user_tinhtrang_daphancong') {
              await _firebaseService.updateTinhTrangYeuCau(
                maYeuCau,
                'user_tinhtrang_daphancong',
              );
              yeuCauCuuHo = yeuCauCuuHo?.copyWith(
                maTinhTrangYeuCau: 'user_tinhtrang_daphancong',
              );
            }

            if (!_hasNavigated && onRescuerAccepted != null) {
              _hasNavigated = true;
              onRescuerAccepted(initialRescuerLocations);
            }
          }

          if (acceptedRescuerIds.length >= limitCans) {
            _stopAllTimers();
            _phanCongSubscription?.cancel();
          }

          onUpdate();
        });
  }

  int get _maxSeconds =>
      yeuCauCuuHo?.maLoaiYeuCau == 'loaiyeucau_choncuuhovien' ? 120 : 60;

  int _stepForElapsed(int sec) {
    final t = sec - _aiStartSecond;
    if (t >= 30) return 2; // 5000m
    if (t >= 15) return 1; // 3000m
    return 0; // 1000m
  }

  void _startTicker(String maYeuCau, Function() onUpdate) {
    _stopwatch
      ..reset()
      ..start();
    _secondsTimer?.cancel();
    _secondsTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final now = _baseSeconds + _stopwatch.elapsed.inSeconds;
      if (now == elapsedSeconds) return;
      elapsedSeconds = now;
      if (!_isOverdueHandled) {
        YeuCauStorageService.saveElapsedSeconds(maYeuCau, elapsedSeconds);
      }

      if (_setupDone && !_isOverdueHandled && !_tickBusy) {
        _tickBusy = true;
        try {
          await _onTick(maYeuCau, onUpdate);
        } catch (e) {
          debugPrint('Lỗi tick tìm kiếm: $e');
        } finally {
          _tickBusy = false;
        }
      }
      onUpdate();
    });
  }

  Future<void> _onTick(String maYeuCau, Function() onUpdate) async {
    if (acceptedRescuerIds.isNotEmpty) return;

    if (elapsedSeconds >= _maxSeconds) {
      await _handleOverdue(maYeuCau);
      return;
    }
    if (elapsedSeconds < _aiStartSecond) return;

    if (!_switchedToAI) {
      _switchedToAI = true;
      if (_aiStartSecond > 0) {
        debugPrint('⏳ Quá 60s nhóm chỉ định không nhận, chuyển sang AI!');
        await _firebaseService.updateTinhTrangYeuCau(
          maYeuCau,
          'user_tinhtrang_chotiepnhan',
        );
      }
    }

    final step = _stepForElapsed(elapsedSeconds);
    final stepChanged = step != currentScanStep;
    if (stepChanged) {
      currentScanStep = step;
      await updateMapOverlays();
    }
    if (stepChanged || (elapsedSeconds - _aiStartSecond) % 3 == 0) {
      await _scanSafely(maYeuCau, onUpdate);
    }
  }

  Future<void> _scanSafely(String maYeuCau, Function() onUpdate) async {
    if (_isScanning) return;
    _isScanning = true;
    try {
      await _executeAIScanAndAssign(maYeuCau, onUpdate);
    } finally {
      _isScanning = false;
    }
  }

  Future<void> _handleOverdue(String maYeuCau) async {
    if (_isOverdueHandled) return;
    _isOverdueHandled = true;
    debugPrint(
      '⏳ Đã quá $_maxSeconds s, chuyển sang QUÁ HẠN (đồng hồ vẫn chạy)!',
    );

    Future<void> safe(String label, Future<dynamic> Function() job) async {
      try {
        await job();
      } catch (e) {
        debugPrint('⚠️ _handleOverdue[$label]: $e');
      }
    }

    await safe(
      'trangThai',
      () => _firebaseService.updateTinhTrangYeuCau(
        maYeuCau,
        'user_tinhtrang_quahandieuphoi',
      ),
    );
    yeuCauCuuHo = yeuCauCuuHo?.copyWith(
      maTinhTrangYeuCau: 'user_tinhtrang_quahandieuphoi',
    );

    await safe('xoaGhiNhoMay', () => YeuCauStorageService.clearActiveRequest());
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
      if (rescuer.viDo == null || rescuer.kinhDo == null) continue;
      if (rescuer.nhanCaCuuHo == true) continue;

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
      // 🌟 Chỉ ghi nhận vào danh sách AI quét được
      aiFoundRescuerIds.add(maNguoiCuuHo);
      initialRescuerLocations[maNguoiCuuHo] = LatLng(user.viDo!, user.kinhDo!);
      rescuerList.add({
        'user': user,
        'distanceKm': distanceKm.toStringAsFixed(1),
      });

      await _addRescuerMarker(user, (item['distanceMeters'] as double));
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

  List<String> _asStringList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : <String>[];

  Future<_RescuerScoreInfo> _getRescuerInfo(String uid) async {
    final cached = _scoreInfoCache[uid];
    if (cached != null) return cached;

    final hoSoF = _firebaseService.getHoSoCoCCHN(uid);
    final skillsF = _firebaseService.getSkillIdsByUserId(uid);
    final hoSo = await hoSoF;
    final skills = await skillsF;

    return _scoreInfoCache[uid] = _RescuerScoreInfo(
      hoSo?.tenChuyenNganh ?? '',
      skills,
    );
  }

  Future<double> _calculateAIScore(
    NguoiDungModel user,
    double distanceMeters,
  ) async {
    double score = 0.0;
    final reqChuyenNganh = _asStringList(
      aiAnalysisResult?['chuyenNganhYeuCau'],
    );
    final reqKyNang = _asStringList(aiAnalysisResult?['kyNangYeuCau']);

    final info = await _getRescuerInfo(user.maNguoiDung!);

    final cn = boDauTiengViet(info.chuyenNganh).trim();
    if (cn.isNotEmpty) {
      for (final req in reqChuyenNganh) {
        final r = boDauTiengViet(req).trim();
        if (r.isEmpty) continue;
        if (cn.contains(r) || r.contains(cn)) score += 8000.0;
      }
    }

    for (final skId in info.skillIds) {
      final s = boDauTiengViet(skId).trim();
      if (s.isEmpty) continue;
      for (final req in reqKyNang) {
        final r = boDauTiengViet(req).trim();
        if (r.isEmpty) continue;
        if (s == r || s.contains(r) || r.contains(s)) {
          score += 5000.0;
          break;
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

    Widget avatarContent;
    bool hasImage = false;

    if (avatarData != null && avatarData.trim().isNotEmpty) {
      final cleaned = avatarData.trim();
      if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
        hasImage = true;
        avatarContent = Image.network(
          cleaned,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      } else {
        final base64Str = cleaned.contains(',')
            ? cleaned.split(',').last.trim()
            : cleaned;
        try {
          final bytes = base64Decode(base64Str);
          hasImage = true;
          avatarContent = Image.memory(
            bytes,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        } catch (e) {
          debugPrint('Lỗi decode Base64 avatar marker: $e');
          avatarContent = Center(
            child: Text(
              _getInitials(user.hoTen),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
        }
      }
    } else {
      avatarContent = Center(
        child: Text(
          _getInitials(user.hoTen),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    String distanceText = distanceMeters < 1000
        ? '${distanceMeters.toStringAsFixed(0)} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

    Widget rescuerMarkerWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasImage ? Colors.white : const Color(0xFF006A55),
                border: Border.all(color: const Color(0xFF006A55), width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(child: avatarContent),
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

    BitmapDescriptor customIcon = await rescuerMarkerWidget.toBitmapDescriptor(
      waitToRender: const Duration(milliseconds: 150),
    );

    markers.removeWhere(
      (m) => m.markerId.value == 'rescuer_${user.maNguoiDung}',
    );
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
    _secondsTimer?.cancel();
    _stopwatch.stop();
  }

  void stopSearchWithoutCanceling() {
    _stopAllTimers();
    _phanCongSubscription?.cancel();
    _disposed = true;
    debugPrint('✅ Đã ngưng quét và tắt stream, giữ nguyên đơn cứu hộ!');
  }

  void dispose() {
    _stopAllTimers();
    _phanCongSubscription?.cancel();
    _disposed = true;
  }

  Future<void> cancelSearch(String maYeuCau) async {
    try {
      isLoading = true;
      _stopAllTimers();
      _phanCongSubscription?.cancel();

      await YeuCauStorageService.clearActiveRequest();

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
