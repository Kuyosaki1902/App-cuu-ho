// controllers/chon_nguoi_cuu_ho_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/models/nguoidungmodel.dart';
import 'package:cuhokhancap/models/hosocuuhococchnmodel.dart';
import 'package:cuhokhancap/models/hosocuuhokhongcchnmodel.dart';

// Model Chuyên ngành
class ChuyenNganhModel {
  final String maChuyenNganh;
  final String tenChuyenNganh;
  ChuyenNganhModel({required this.maChuyenNganh, required this.tenChuyenNganh});
}

// Wrapper Item chứa thông tin hiển thị
class ItemNguoiCuuHo {
  final NguoiDungModel nguoiDung;
  final HoSoCuuHoCoCCHNModel? hoSoCoCCHN;
  final HoSoCuuHoKhongCCHNModel? hoSoKhongCCHN;
  final int khoangCachMet;
  final String thoiGianDen;
  final String maChuyenNganh;
  final String tenChuyenNganh;

  ItemNguoiCuuHo({
    required this.nguoiDung,
    this.hoSoCoCCHN,
    this.hoSoKhongCCHN,
    required this.khoangCachMet,
    required this.thoiGianDen,
    required this.maChuyenNganh,
    required this.tenChuyenNganh,
  });

  bool get coCCHN => hoSoCoCCHN != null;

  double get rating => coCCHN
      ? (hoSoCoCCHN?.diemDanhGia ?? 5.0)
      : (hoSoKhongCCHN?.diemDanhGia ?? 5.0);

  int get reviewsCount => coCCHN
      ? (hoSoCoCCHN?.tongLuotDanhGia ?? 0)
      : (hoSoKhongCCHN?.tongLuotDanhGia ?? 0);

  String get formattedDistance => khoangCachMet >= 1000
      ? '${(khoangCachMet / 1000).toStringAsFixed(1)}km'
      : '${khoangCachMet}m';

  String get timeArrival => '$thoiGianDen phút đến';

  String get initials {
    final parts = nguoiDung.hoTen.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0].toUpperCase()
        : 'CH';
  }
}

class ChonNguoiCuuHoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy dữ liệu người cứu hộ từ Firestore
  Future<Map<String, dynamic>> fetchDoctorsFromFirestore(
    Map<String, dynamic> dsNguoiCuuHoMap,
  ) async {
    List<ItemNguoiCuuHo> loadedList = [];
    List<ChuyenNganhModel> tempChuyenNganh = [
      ChuyenNganhModel(maChuyenNganh: "ALL", tenChuyenNganh: "Tất Cả"),
      ChuyenNganhModel(
        maChuyenNganh: 'CuuHoTuDo',
        tenChuyenNganh: "Cứu Hộ Tự Do",
      ),
    ];

    try {
      for (var entry in dsNguoiCuuHoMap.entries) {
        final String maNguoiDung = entry.key;

        // Bóc tách Map con
        final Map<String, dynamic> infoMap = Map<String, dynamic>.from(
          entry.value,
        );
        final int khoangCachMet = (infoMap['khoangcach'] as num?)?.toInt() ?? 0;
        final String thoiGianDen = infoMap['thoigian']?.toString() ?? '10~15';

        // 1. Lấy NguoiDungModel
        final userDoc = await _firestore
            .collection('NguoiDung')
            .doc(maNguoiDung)
            .get();
        if (!userDoc.exists || userDoc.data() == null) continue;
        final userModel = NguoiDungModel.fromMap(userDoc.data()!);

        // 2. Query Hồ sơ Có CCHN
        final cchnQuery = await _firestore
            .collection('HoSoCuuHoCoCCHN')
            .where('maNguoiDung', isEqualTo: maNguoiDung)
            .limit(1)
            .get();

        HoSoCuuHoCoCCHNModel? hoSoCoCCHN;
        HoSoCuuHoKhongCCHNModel? hoSoKhongCCHN;

        String maCN = 'CuuHoTuDo';
        String tenCN = 'Cứu Hộ Tự Do';

        if (cchnQuery.docs.isNotEmpty) {
          hoSoCoCCHN = HoSoCuuHoCoCCHNModel.fromMap(
            cchnQuery.docs.first.data(),
            cchnQuery.docs.first.id,
          );

          maCN = hoSoCoCCHN.maTheChuyenNganh;
          tenCN = hoSoCoCCHN.tenChuyenNganh.isNotEmpty
              ? hoSoCoCCHN.tenChuyenNganh
              : (hoSoCoCCHN.chucDanh.isNotEmpty
                    ? hoSoCoCCHN.chucDanh
                    : 'Chuyên Khoa Cấp Cứu');

          bool daTonTai = tempChuyenNganh.any((cn) => cn.maChuyenNganh == maCN);
          if (!daTonTai) {
            tempChuyenNganh.add(
              ChuyenNganhModel(maChuyenNganh: maCN, tenChuyenNganh: tenCN),
            );
          }
        } else {
          // 3. Query Hồ sơ Không CCHN -> Đưa vào Cứu Hộ Tự Do
          final khongCchnQuery = await _firestore
              .collection('HoSoCuuHoKhongCCHN')
              .where('maNguoiDung', isEqualTo: maNguoiDung)
              .limit(1)
              .get();

          if (khongCchnQuery.docs.isNotEmpty) {
            hoSoKhongCCHN = HoSoCuuHoKhongCCHNModel.fromMap(
              khongCchnQuery.docs.first.data(),
              khongCchnQuery.docs.first.id,
            );
          }

          maCN = 'CuuHoTuDo';
          tenCN = 'Cứu Hộ Tự Do';
        }

        loadedList.add(
          ItemNguoiCuuHo(
            nguoiDung: userModel,
            hoSoCoCCHN: hoSoCoCCHN,
            hoSoKhongCCHN: hoSoKhongCCHN,
            khoangCachMet: khoangCachMet,
            thoiGianDen: thoiGianDen,
            maChuyenNganh: maCN,
            tenChuyenNganh: tenCN,
          ),
        );
      }

      loadedList.sort((a, b) => a.khoangCachMet.compareTo(b.khoangCachMet));
    } catch (e) {
      print('Lỗi Controller ChonNguoiCuuHo: $e');
    }

    return {'doctors': loadedList, 'categories': tempChuyenNganh};
  }
}
