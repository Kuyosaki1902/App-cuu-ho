// controllers/chon_nguoi_cuu_ho_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/firebase/firebase_service.dart';
import 'package:geolocator/geolocator.dart';

class ChonNguoiCuuHoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  Future<Map<String, dynamic>> fetchNearbyDoctors(
    Position currentPosition,
    double maxRadiusMeters,
  ) async {
    List<Map<String, dynamic>> loadedList = [];

    try {
      List<dynamic> onlineRescuers = await _firebaseService.getOnlineRescuers();

      for (var user in onlineRescuers) {
        if (user.viDo == null || user.kinhDo == null) continue;

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

            danhSachKyNang = await _firebaseService.getSkillIdsByUserId(
              user.maNguoiDung!,
            );
          }

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
