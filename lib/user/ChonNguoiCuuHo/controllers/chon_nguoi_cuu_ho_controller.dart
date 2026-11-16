// controllers/chon_nguoi_cuu_ho_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:geolocator/geolocator.dart';

class ChonNguoiCuuHoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Lấy danh sách TÊN kỹ năng từ /ChiTietKyNang/{userId}/DanhSachKyNang
  // và tra cứu tên tại /KyNangCuuHo/kynangcoban/DanhSachKyNang & /KyNangCuuHo/kynangtuhoc/DanhSachKyNang
  Future<List<String>> _fetchTenKyNangByUserId(String userId) async {
    try {
      final chiTietSnap = await _firestore
          .collection('ChiTietKyNang')
          .doc(userId)
          .collection('DanhSachKyNang')
          .get();

      if (chiTietSnap.docs.isEmpty) return [];

      final List<String> skillIds = [];
      for (final doc in chiTietSnap.docs) {
        final data = doc.data();
        final rawId = (data['maKyNangCuuHo'] ?? '').toString().trim();
        skillIds.add(rawId.isNotEmpty ? rawId : doc.id);
      }

      final List<String> tenKyNangList = [];
      final coBanRef = _firestore
          .collection('KyNangCuuHo')
          .doc('kynangcoban')
          .collection('DanhSachKyNang');
      final tuHocRef = _firestore
          .collection('KyNangCuuHo')
          .doc('kynangtuhoc')
          .collection('DanhSachKyNang');

      for (final skillId in skillIds) {
        // 1. Tìm trong nhóm kynangcoban
        final docCoBan = await coBanRef.doc(skillId).get();
        if (docCoBan.exists && docCoBan.data() != null) {
          final ten = (docCoBan.data()!['ten'] ?? '').toString().trim();
          if (ten.isNotEmpty) {
            tenKyNangList.add(ten);
            continue;
          }
        }

        // 2. Nếu không có trong cơ bản thì tìm trong nhóm kynangtuhoc
        final docTuHoc = await tuHocRef.doc(skillId).get();
        if (docTuHoc.exists && docTuHoc.data() != null) {
          final ten = (docTuHoc.data()!['ten'] ?? '').toString().trim();
          if (ten.isNotEmpty) {
            tenKyNangList.add(ten);
          }
        }
      }

      return tenKyNangList;
    } catch (e) {
      print('Lỗi lấy danh sách tên kỹ năng cho $userId: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchNearbyDoctors(
    Position currentPosition,
    double maxRadiusMeters,
  ) async {
    List<Map<String, dynamic>> loadedList = [];

    try {
      List<dynamic> onlineRescuers = await _firebaseService.getOnlineRescuers();

      for (var user in onlineRescuers) {
        if (user.viDo == null || user.kinhDo == null) continue;

        // Kiểm tra trực tiếp trường nhanCaCuuHo trên NguoiDung: nếu đang nhận ca (true) thì bỏ qua
        if (user.maNguoiDung != null && user.maNguoiDung!.isNotEmpty) {
          final userDoc = await _firestore
              .collection('NguoiDung')
              .doc(user.maNguoiDung)
              .get();
          if (userDoc.exists && userDoc.data()?['nhanCaCuuHo'] == true) {
            continue;
          }
        }

        double distanceMeters = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          user.viDo!,
          user.kinhDo!,
        );

        if (distanceMeters <= maxRadiusMeters) {
          int khoangCachMet = distanceMeters.round();
          String thoiGianDen = ((distanceMeters / 1000) * 4).round().toString();
          if (thoiGianDen == "0") thoiGianDen = "1";

          final cchnQuery = await _firestore
              .collection('HoSoCuuHoCoCCHN')
              .where('maNguoiDung', isEqualTo: user.maNguoiDung)
              .limit(1)
              .get();

          bool coCCHN = cchnQuery.docs.isNotEmpty;
          String maCN = 'CuuHoTuDo';
          String tenCN = 'Cứu Hộ Tự Do';
          double rating = 5.0;
          int reviewsCount = 0;
          List<String> danhSachKyNang = [];

          if (coCCHN) {
            final dataCCHN = cchnQuery.docs.first.data();
            maCN = dataCCHN['maTheChuyenNganh'] ?? 'CuuHoTuDo';
            tenCN = (dataCCHN['tenChuyenNganh'] ?? '').toString().isNotEmpty
                ? dataCCHN['tenChuyenNganh']
                : ((dataCCHN['chucDanh'] ?? '').toString().isNotEmpty
                      ? dataCCHN['chucDanh']
                      : 'Chuyên Khoa Cấp Cứu');
            rating = (dataCCHN['diemDanhGia'] as num?)?.toDouble() ?? 5.0;
            reviewsCount = (dataCCHN['tongLuotDanhGia'] as num?)?.toInt() ?? 0;
          } else {
            final khongCchnQuery = await _firestore
                .collection('HoSoCuuHoKhongCCHN')
                .where('maNguoiDung', isEqualTo: user.maNguoiDung)
                .limit(1)
                .get();

            if (khongCchnQuery.docs.isNotEmpty) {
              final dataKhongCCHN = khongCchnQuery.docs.first.data();
              rating =
                  (dataKhongCCHN['diemDanhGia'] as num?)?.toDouble() ?? 5.0;
              reviewsCount =
                  (dataKhongCCHN['tongLuotDanhGia'] as num?)?.toInt() ?? 0;
            }

            danhSachKyNang = await _fetchTenKyNangByUserId(user.maNguoiDung!);
          }

          // Lấy chuỗi base64 / URL avatar từ collection LuuAnh
          final String? avatarUrl = await _firebaseService.getUserAvatarUrl(
            user.maNguoiDung!,
          );

          String formattedDistance = khoangCachMet >= 1000
              ? '${(khoangCachMet / 1000).toStringAsFixed(1)}km'
              : '${khoangCachMet}m';

          List<String> parts = user.hoTen.trim().split(' ');
          String initials = 'CH';
          if (parts.length >= 2) {
            initials = '${parts[parts.length - 2][0]}${parts.last[0]}'
                .toUpperCase();
          } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
            initials = parts.first[0].toUpperCase();
          }

          loadedList.add({
            'nguoiDung': user,
            'avatarUrl': avatarUrl,
            'coCCHN': coCCHN,
            'maChuyenNganh': maCN,
            'tenChuyenNganh': tenCN,
            'rating': rating,
            'reviewsCount': reviewsCount,
            'khoangCachMet': khoangCachMet,
            'formattedDistance': formattedDistance,
            'thoiGianDen': '$thoiGianDen phút đến',
            'initials': initials,
            'danhSachKyNang': danhSachKyNang,
          });
        }
      }

      loadedList.sort(
        (a, b) =>
            (a['khoangCachMet'] as int).compareTo(b['khoangCachMet'] as int),
      );
    } catch (e) {
      print('Lỗi Controller ChonNguoiCuuHo: $e');
    }

    return {'doctors': loadedList};
  }
}
