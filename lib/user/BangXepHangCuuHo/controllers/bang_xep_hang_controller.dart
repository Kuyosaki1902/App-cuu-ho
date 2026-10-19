// lib/BangXepHangCuuHo/controllers/bang_xep_hang_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/models/nguoidungmodel.dart';
import 'package:cuhokhancap/user/models/hosocuuhococchnmodel.dart';
import 'package:cuhokhancap/user/models/hosocuuhokhongcchnmodel.dart';

class RescuerLeaderboardItemModel {
  final int rank;
  final NguoiDungModel user;
  final int casesCount;
  final String specialty;
  final String organization;
  final double rating;
  final int reviewsCount;

  RescuerLeaderboardItemModel({
    required this.rank,
    required this.user,
    required this.casesCount,
    required this.specialty,
    required this.organization,
    required this.rating,
    required this.reviewsCount,
  });
}

class BangXepHangController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<RescuerLeaderboardItemModel>> fetchLeaderboard(
    int selectedTab,
  ) async {
    // 0: Tuần này ('tuan'), 1: Tháng này ('thang'), 2: Tất cả ('tatCa')
    String filterKey = 'tuan';
    if (selectedTab == 1) {
      filterKey = 'thang';
    } else if (selectedTab == 2) {
      filterKey = 'tatCa';
    }

    // ⚡ 1. Đọc song song cả 2 collection Hồ sơ
    final results = await Future.wait([
      _firestore.collection('HoSoCuuHoCoCCHN').get(),
      _firestore.collection('HoSoCuuHoKhongCCHN').get(),
    ]);

    List<Map<String, dynamic>> rawDataList = [];
    Set<String> userIdsSet = {};

    // 2. Trích xuất thông tin hồ sơ có CCHN
    for (var doc in results[0].docs) {
      final data = doc.data();
      final hoSo = HoSoCuuHoCoCCHNModel.fromMap(data, doc.id);

      int cases = 0;
      if (data['soLuongCaHoanThanh'] is Map) {
        cases = (data['soLuongCaHoanThanh'][filterKey] as num?)?.toInt() ?? 0;
      } else if (data['soLuongCaHoanThanh'] is num) {
        cases = (data['soLuongCaHoanThanh'] as num).toInt();
      }

      if (hoSo.maNguoiDung != null && hoSo.maNguoiDung!.isNotEmpty) {
        userIdsSet.add(hoSo.maNguoiDung!);
        rawDataList.add({
          'userId': hoSo.maNguoiDung,
          'cases': cases,
          'specialty': hoSo.tenChuyenNganh.isNotEmpty
              ? hoSo.tenChuyenNganh
              : hoSo.chucDanh,
          'organization': hoSo.donViCongTac.isNotEmpty
              ? hoSo.donViCongTac
              : 'Đội Cứu hộ Y tế',
          'rating': hoSo.diemDanhGia,
          'reviewsCount': hoSo.tongLuotDanhGia,
        });
      }
    }

    // 3. Trích xuất thông tin hồ sơ KHÔNG CCHN
    for (var doc in results[1].docs) {
      final data = doc.data();
      final hoSo = HoSoCuuHoKhongCCHNModel.fromMap(data, doc.id);

      int cases = 0;
      if (data['soLuongCaHoanThanh'] is Map) {
        cases = (data['soLuongCaHoanThanh'][filterKey] as num?)?.toInt() ?? 0;
      } else if (data['soLuongCaHoanThanh'] is num) {
        cases = (data['soLuongCaHoanThanh'] as num).toInt();
      }

      if (hoSo.maNguoiDung != null && hoSo.maNguoiDung!.isNotEmpty) {
        userIdsSet.add(hoSo.maNguoiDung!);
        rawDataList.add({
          'userId': hoSo.maNguoiDung,
          'cases': cases,
          'specialty': 'Cứu hộ & Hỗ trợ cộng đồng',
          'organization': hoSo.doiNhom ?? 'Tình nguyện viên Cứu hộ',
          'rating': hoSo.diemDanhGia,
          'reviewsCount': hoSo.tongLuotDanhGia,
        });
      }
    }

    if (userIdsSet.isEmpty) return [];

    // ⚡ 4. Lấy NguoiDung song song qua whereIn (Tối ưu từ N+1 query về 1 query)
    List<String> userIds = userIdsSet.toList();
    Map<String, NguoiDungModel> userMap = {};

    for (var i = 0; i < userIds.length; i += 30) {
      var chunk = userIds.sublist(
        i,
        i + 30 > userIds.length ? userIds.length : i + 30,
      );
      var userSnapshots = await _firestore
          .collection('NguoiDung')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (var doc in userSnapshots.docs) {
        if (doc.exists && doc.data() != null) {
          // 🌟 Gọi fromMap với chỉ doc.data()! đúng yêu cầu
          userMap[doc.id] = NguoiDungModel.fromMap(doc.data()!);
        }
      }
    }

    // 5. Ghép dữ liệu & Sắp xếp giảm dần theo số ca
    List<RescuerLeaderboardItemModel> fullList = [];
    for (var raw in rawDataList) {
      final String uid = raw['userId'];
      if (userMap.containsKey(uid)) {
        fullList.add(
          RescuerLeaderboardItemModel(
            rank: 0,
            user: userMap[uid]!,
            casesCount: raw['cases'],
            specialty: raw['specialty'],
            organization: raw['organization'],
            rating: raw['rating'],
            reviewsCount: raw['reviewsCount'],
          ),
        );
      }
    }

    fullList.sort((a, b) => b.casesCount.compareTo(a.casesCount));

    return List.generate(fullList.length, (index) {
      final item = fullList[index];
      return RescuerLeaderboardItemModel(
        rank: index + 1,
        user: item.user,
        casesCount: item.casesCount,
        specialty: item.specialty,
        organization: item.organization,
        rating: item.rating,
        reviewsCount: item.reviewsCount,
      );
    });
  }
}
