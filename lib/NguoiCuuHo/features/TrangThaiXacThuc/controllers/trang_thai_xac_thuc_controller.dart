import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/trang_thai_ho_so.dart';

enum MucTienDo { dat, dangCho, canXuLy }

/// Một dòng trong checklist tiến độ hồ sơ.
class MucKiemTra {
  final String tieuDe;
  final String moTa;
  final MucTienDo trangThai;
  const MucKiemTra({
    required this.tieuDe,
    required this.moTa,
    required this.trangThai,
  });
}

class TrangThaiXacThucController extends ChangeNotifier {
  final String userId;
  final bool isCoCCHN;

  // --- Trạng thái tải ---
  bool isRefreshing = false;
  bool daTaiLanDau = false; // đã nhận ít nhất 1 phản hồi từ Firestore
  bool hoSoTonTai = true;
  String? loiTaiDuLieu;

  // --- Dữ liệu hồ sơ ---
  TrangThaiHoSo trangThai = TrangThaiHoSo.tiepNhan;
  String maTrangThaiRaw = '';
  String maHoSo = '';
  String? lyDo; // lyDoTuChoi do người duyệt ghi
  int capDoUyTin = 0;
  DateTime? thoiGianNop;
  List<MucKiemTra> tienDo = const [];

  // --- Đếm ngược ---
  String thoiGianThamDinh = 'Dự kiến tối đa $kThamDinhSlaGio giờ';
  String thoiGianConLai = 'Đang cập nhật';

  Map<String, dynamic> _hoSo = {};
  List<Map<String, dynamic>> _minhChung = [];
  List<Map<String, dynamic>> _baoChung = [];

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _hoSoSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _minhChungSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _baoChungSub;
  Timer? _timer;
  Timer? _loadTimeout;
  bool _disposed = false;

  TrangThaiXacThucController({required this.userId, this.isCoCCHN = false}) {
    maHoSo = _maNgan(userId);
    _listen();
  }

  String get trangThaiText => trangThai.label;

  String get _hoSoCollection =>
      isCoCCHN ? 'HoSoCuuHoCoCCHN' : 'HoSoCuuHoKhongCCHN';

  /// Mã hiển thị ngắn thay vì lộ nguyên UID. Nếu server đã cấp `maHoSo` thì dùng mã đó.
  String _maNgan(String id) {
    final tail = id.substring(math.max(0, id.length - 8)).toUpperCase();
    return 'HS-$tail';
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  Future<void> requestNotificationPermission() async {
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('Không xin được quyền thông báo: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Lắng nghe thời gian thực
  // ---------------------------------------------------------------------------
  void _cancelSubs() {
    _hoSoSub?.cancel();
    _minhChungSub?.cancel();
    _baoChungSub?.cancel();
    _hoSoSub = _minhChungSub = _baoChungSub = null;
  }

  void _listen() {
    _cancelSubs();
    isRefreshing = true;
    notifyListeners();

    final db = FirebaseFirestore.instance;

    _hoSoSub = db
        .collection(_hoSoCollection)
        .doc(userId)
        .snapshots()
        .listen(_onHoSo, onError: _onError);

    // Minh chứng và người bảo chứng chỉ có ở luồng không CCHN.
    if (!isCoCCHN) {
      _minhChungSub = db
          .collection('MinhChung')
          .where('maNguoiDung', isEqualTo: userId)
          .snapshots()
          .listen((snap) {
        _minhChung = snap.docs.map((d) => d.data()).toList();
        _rebuild();
      }, onError: _onError);

      _baoChungSub = db
          .collection('NguoiBaoChung')
          .where('maNguoiDung', isEqualTo: userId)
          .snapshots()
          .listen((snap) {
        _baoChung = snap.docs.map((d) => d.data()).toList();
        _rebuild();
      }, onError: _onError);
    }

    // Offline và chưa có cache thì stream không phát gì: tránh quay mãi.
    _loadTimeout?.cancel();
    _loadTimeout = Timer(const Duration(seconds: 10), () {
      if (isRefreshing) {
        isRefreshing = false;
        loiTaiDuLieu ??= 'Không kết nối được máy chủ. Vui lòng kiểm tra mạng.';
        notifyListeners();
      }
    });
  }

  /// Nút "Làm mới": đăng ký lại các luồng dữ liệu.
  void refresh() => _listen();

  void _onError(Object e) {
    debugPrint('🔴 Lỗi tải trạng thái hồ sơ: $e');
    isRefreshing = false;
    loiTaiDuLieu = 'Không tải được dữ liệu. Vui lòng thử lại.';
    notifyListeners();
  }

  void _onHoSo(DocumentSnapshot<Map<String, dynamic>> doc) {
    _loadTimeout?.cancel();
    isRefreshing = false;
    daTaiLanDau = true;
    loiTaiDuLieu = null;

    final data = doc.data();
    if (!doc.exists || data == null) {
      hoSoTonTai = false;
      _timer?.cancel();
      notifyListeners();
      return;
    }

    hoSoTonTai = true;
    _hoSo = data;
    maTrangThaiRaw = (data['maTrangThaiHoSo'] ?? '').toString().trim();
    trangThai = trangThaiTuMa(maTrangThaiRaw);
    maHoSo = (data['maHoSo'] ?? _maNgan(userId)).toString();
    final lyDoRaw = (data['lyDoTuChoi'] ?? '').toString().trim();
    lyDo = lyDoRaw.isEmpty ? null : lyDoRaw;
    capDoUyTin = (data['capDoUyTin'] is int) ? data['capDoUyTin'] as int : 0;
    // thoiGianNop là serverTimestamp (có thể tạm null ở bản ghi chưa đồng bộ),
    // khi đó dùng thoiGianOnline làm dự phòng.
    thoiGianNop = _parseTime(data['thoiGianNop']) ??
        _parseTime(data['thoiGianOnline']);
    _rebuild();
  }

  DateTime? _parseTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  // ---------------------------------------------------------------------------
  // Dựng lại giao diện từ dữ liệu hiện có
  // ---------------------------------------------------------------------------
  void _rebuild() {
    if (!daTaiLanDau || !hoSoTonTai) return;
    tienDo = _buildTienDo();
    _updateCountdown();
    notifyListeners();
  }

  void _updateCountdown() {
    _timer?.cancel();
    if (!trangThai.dangCho) return;

    final nop = thoiGianNop;
    if (nop == null) {
      thoiGianConLai = 'Đang cập nhật';
      return;
    }
    final target = nop.add(const Duration(hours: kThamDinhSlaGio));
    _tinhConLai(target);
    if (target.isBefore(DateTime.now())) return; // đã quá hạn, không cần timer
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _tinhConLai(target);
      notifyListeners();
    });
  }

  void _tinhConLai(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.inMinutes <= 0) {
      // Quá hạn dự kiến không có nghĩa là bị từ chối, chỉ là chưa xử lý xong.
      thoiGianConLai = 'Quá hạn dự kiến';
      _timer?.cancel();
    } else {
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
      thoiGianConLai = 'Còn ~${h}h${m}m';
    }
  }

  List<MucKiemTra> _buildTienDo() {
    final daDuyet = trangThai == TrangThaiHoSo.daDuyet;

    // Danh tính (CCCD + selfie) / CCHN: theo trạng thái chung của hồ sơ.
    MucTienDo chung;
    switch (trangThai) {
      case TrangThaiHoSo.daDuyet:
      case TrangThaiHoSo.tamKhoa:
        chung = MucTienDo.dat;
        break;
      case TrangThaiHoSo.canBoSung:
      case TrangThaiHoSo.tuChoi:
        chung = MucTienDo.canXuLy;
        break;
      default:
        chung = MucTienDo.dangCho;
    }

    String moTaChung(String cho, String dat, String loi) {
      switch (chung) {
        case MucTienDo.dat:
          return dat;
        case MucTienDo.canXuLy:
          return loi;
        case MucTienDo.dangCho:
          return cho;
      }
    }

    if (isCoCCHN) {
      return [
        MucKiemTra(
          tieuDe: 'Danh tính và giấy phép hành nghề',
          moTa: moTaChung(
            'Người duyệt đang đối chiếu CCCD, ảnh và số CCHN/GPHN với danh sách công khai',
            'Đã đối chiếu',
            'Cần kiểm tra lại giấy tờ, xem lý do bên trên',
          ),
          trangThai: chung,
        ),
      ];
    }

    final muc = <MucKiemTra>[];

    muc.add(MucKiemTra(
      tieuDe: 'Danh tính (CCCD và selfie)',
      moTa: moTaChung(
        'Người duyệt đang đối chiếu CCCD và ảnh selfie',
        'Đã đối chiếu',
        'Cần chụp lại hoặc bổ sung giấy tờ, xem lý do bên trên',
      ),
      trangThai: chung,
    ));

    // Minh chứng chính (không tính ảnh hoạt động, chỉ là bổ trợ).
    final chinh =
        _minhChung.where((m) => m['loai'] != 'anh_hoatdong').toList();
    MucTienDo mc;
    String mcMoTa;
    if (daDuyet || chinh.any((m) => m['trangThai'] == 'hople')) {
      mc = MucTienDo.dat;
      mcMoTa = 'Minh chứng hợp lệ';
    } else if (chinh.isNotEmpty &&
        chinh.every((m) => m['trangThai'] == 'khonghople')) {
      mc = MucTienDo.canXuLy;
      mcMoTa = 'Minh chứng chưa hợp lệ, cần nộp lại';
    } else {
      mc = MucTienDo.dangCho;
      mcMoTa = 'Đang chờ người duyệt kiểm tra';
    }
    muc.add(MucKiemTra(
      tieuDe: 'Minh chứng sơ cấp cứu / tổ chức',
      moTa: mcMoTa,
      trangThai: mc,
    ));

    // Người bảo chứng.
    final daXacNhan = _baoChung.any((b) => b['daXacNhan'] == true);
    String bcMoTa;
    if (daXacNhan) {
      bcMoTa = 'Người bảo chứng đã xác nhận';
    } else if (_baoChung.isNotEmpty) {
      final ten = (_baoChung.first['hoTen'] ?? '').toString();
      bcMoTa = ten.isEmpty
          ? 'Đang chờ người bảo chứng xác nhận'
          : 'Đang chờ $ten xác nhận. Hãy nhắc họ trả lời tin nhắn/cuộc gọi';
    } else {
      bcMoTa = 'Chưa có thông tin người bảo chứng';
    }
    muc.add(MucKiemTra(
      tieuDe: 'Người bảo chứng',
      moTa: bcMoTa,
      trangThai: (daDuyet || daXacNhan) ? MucTienDo.dat : MucTienDo.dangCho,
    ));

    // Bài kiểm tra: điểm do app chấm, người duyệt/server đối chiếu lại.
    final diem = _hoSo['diemBaiKiemTra'];
    final tong = _hoSo['tongCauBaiKiemTra'];
    final coDiem = diem is int && tong is int && tong > 0;
    muc.add(MucKiemTra(
      tieuDe: 'Bài kiểm tra năng lực',
      moTa: coDiem
          ? 'Đạt $diem/$tong câu'
          : 'Chưa có kết quả bài kiểm tra',
      trangThai: coDiem ? MucTienDo.dat : MucTienDo.dangCho,
    ));

    return muc;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _loadTimeout?.cancel();
    _cancelSubs();
    super.dispose();
  }
}
