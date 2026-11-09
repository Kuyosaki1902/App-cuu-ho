import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ManHinhLichSuCaController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _selectedDate = DateTime.now();
  int _timeModeIndex = 0; // 0: Hôm nay, 1: Tuần này, 2: Tháng này
  int _statusFilterIndex =
      0; // 0: Tất cả, 1: Hoàn thành, 2: Đã hủy, 3: Chờ/Đang xử lý
  String _searchQuery = '';
  bool _isDisposed = false;

  // Stream Cache để tránh giật lag Rebuild
  Stream<QuerySnapshot>? _currentStream;
  String _lastFetchedUserId = '';
  String _lastFetchedDateStr = '';

  DateTime get selectedDate => _selectedDate;
  int get timeModeIndex => _timeModeIndex;
  int get statusFilterIndex => _statusFilterIndex;
  String get searchQuery => _searchQuery;

  void navigateDate(bool isForward) {
    int multiplier = isForward ? 1 : -1;
    if (_timeModeIndex == 0) {
      _selectedDate = _selectedDate.add(Duration(days: 1 * multiplier));
    } else if (_timeModeIndex == 1) {
      _selectedDate = _selectedDate.add(Duration(days: 7 * multiplier));
    } else if (_timeModeIndex == 2) {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + multiplier,
        _selectedDate.day,
      );
    }
    _currentStream = null; // Reset cache stream khi đổi ngày
    notifyListeners();
  }

  void setTimeModeIndex(int index) {
    _timeModeIndex = index;
    _selectedDate = DateTime.now();
    _currentStream = null;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _currentStream = null;
    notifyListeners();
  }

  void setStatusFilterIndex(int index) {
    _statusFilterIndex = index;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  String getFormattedDateRange() {
    if (_timeModeIndex == 0) {
      return DateFormat('dd/MM/yyyy').format(_selectedDate);
    } else if (_timeModeIndex == 1) {
      DateTime monday = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      DateTime sunday = monday.add(const Duration(days: 6));
      return '${DateFormat('dd/MM').format(monday)} -${DateFormat('dd/MM/yyyy').format(sunday)}';
    } else {
      return 'Tháng ${DateFormat('MM/yyyy').format(_selectedDate)}';
    }
  }

  // Lấy Stream và Cache lại để tránh bị Re-subscribe gây giật lag
  Stream<QuerySnapshot> getRescueHistoryStream(String userId) {
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (_currentStream != null &&
        _lastFetchedUserId == userId &&
        _lastFetchedDateStr == dateStr) {
      return _currentStream!;
    }

    _lastFetchedUserId = userId;
    _lastFetchedDateStr = dateStr;

    _currentStream = _firestore
        .collection('ChiTietPhanCongCuuHo')
        .doc(userId)
        .collection('DanhSachNgay')
        .doc(dateStr)
        .collection('DanhSachPhanCong')
        .snapshots();

    return _currentStream!;
  }

  Map<String, dynamic> getStatusStyle(String maTrangThai) {
    switch (maTrangThai) {
      case 'cuuho_trangthai_phancong_hoanthanh':
        return {
          'text': 'Hoàn thành',
          'bgColor': const Color(0xFFA7F3D0),
          'textColor': const Color(0xFF047857),
          'borderColor': const Color(0xFF059669),
          'ratio': 1.0,
        };
      case 'cuuho_trangthai_phancong_dahuy':
        return {
          'text': 'Đã hủy',
          'bgColor': const Color(0xFFFEE2E2),
          'textColor': const Color(0xFF991B1B),
          'borderColor': const Color(0xFFDC2626),
          'ratio': 0.0,
        };
      case 'cuuho_trangthai_phancong_dangthuchien':
        return {
          'text': 'Đang cứu trợ',
          'bgColor': const Color(0xFFE0F2FE),
          'textColor': const Color(0xFF0369A1),
          'borderColor': const Color(0xFF0284C7),
          'ratio': 0.65,
        };
      default:
        return {
          'text': 'Chờ tiếp nhận',
          'bgColor': const Color(0xFFFEF3C7),
          'textColor': const Color(0xFFB45309),
          'borderColor': const Color(0xFFF59E0B),
          'ratio': 0.25,
        };
    }
  }

  // Hàm tính toán số lượng thống kê theo danh sách snapshot từ Firestore
  Map<String, int> calculateStatistics(List<QueryDocumentSnapshot> docs) {
    int tongSoCa = docs.length;
    int hoanThanh = 0;
    int daHuy = 0;
    int dangCuuTro = 0;
    int choTiepNhan = 0;

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      String status = data['maTrangThaiTiepNhan'] ?? '';

      switch (status) {
        case 'cuuho_trangthai_phancong_hoanthanh':
          hoanThanh++;
          break;
        case 'cuuho_trangthai_phancong_dahuy':
          daHuy++;
          break;
        case 'cuuho_trangthai_phancong_dangthuchien':
          dangCuuTro++;
          break;
        default:
          choTiepNhan++;
          break;
      }
    }

    return {
      'tong': tongSoCa,
      'hoanThanh': hoanThanh,
      'daHuy': daHuy,
      'dangCuuTro': dangCuuTro,
      'choTiepNhan': choTiepNhan,
    };
  }

  String formatTimeText(dynamic timestamp) {
    if (timestamp == null) return '--:--';
    if (timestamp is Timestamp) {
      return DateFormat('HH:mm:ss').format(timestamp.toDate());
    }
    if (timestamp is String) {
      try {
        DateTime parsed = DateTime.parse(timestamp);
        return DateFormat('HH:mm:ss').format(parsed);
      } catch (_) {
        return timestamp;
      }
    }
    return '--:--';
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    if (lat == 0.0 || lng == 0.0 || lat.isNaN || lng.isNaN) {
      return 'Đang định vị...';
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=vi',
    );

    try {
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
          String fullAddress = data['display_name'];
          return fullAddress;
        }
      }
    } catch (e) {
      debugPrint('Lỗi Reverse Geocoding OSM: $e');
    }

    return 'Vị trí sự cố thực tế ($lat,$lng)';
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
