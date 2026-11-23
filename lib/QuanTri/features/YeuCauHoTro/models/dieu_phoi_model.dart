import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'yeu_cau_ho_tro_model.dart';

bool coTheDieuPhoi(Object? status) => const [
  'cho_tiep_nhan',
  'qua_han_dieu_phoi',
  'da_phan_cong',
  'dang_cuu_ho',
].contains(normalizeRequestStatus(status));

const pendingAssignmentCodes = [
  'da_gui_thong_bao',
  'cuuho_trangthai_chophanhoi',
  'cuuho_trangthai_phancong_chotiepnhan',
];

const activeAssignmentCodes = [
  'da_dong_y',
  'duoc_chon',
  'cuuho_trangthai_phancong_tiepnhan',
  'cuuho_trangthai_phancong_daphancong',
  'cuuho_trangthai_phancong_daden',
  'cuuho_trangthai_phancong_dangcuuho',
];

const openAssignmentCodes = [
  ...pendingAssignmentCodes,
  ...activeAssignmentCodes,
];

bool sanSangHoTro(
  Map<String, dynamic> user,
  Map<String, dynamic> restriction, {
  required bool hasOpenAssignment,
}) =>
    user['isOnline'] == true &&
    user['nhanCaCuuHo'] != true &&
    restriction['khoa'] != true &&
    restriction['tamNgungHoTro'] != true &&
    !hasOpenAssignment;

double khoangCachKm(double lat1, double lng1, double lat2, double lng2) {
  const radians = math.pi / 180;
  final a =
      math.pow(math.sin((lat2 - lat1) * radians / 2), 2) +
      math.cos(lat1 * radians) *
          math.cos(lat2 * radians) *
          math.pow(math.sin((lng2 - lng1) * radians / 2), 2);
  return 6371 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
}

class DiemDanhGiaCuuHo {
  final double trungBinh;
  final int soLuot;
  const DiemDanhGiaCuuHo(this.trungBinh, this.soLuot);
}

class UngVienDieuPhoi {
  final String uid, name, unit, restrictionReason;
  final bool coCCHN, khongCCHN, ready, eligible;
  final double latitude, longitude, distance;
  final double? ratingAverage;
  final int ratingCount;
  final Set<String> skills;
  const UngVienDieuPhoi({
    required this.uid,
    required this.name,
    required this.unit,
    this.restrictionReason = '',
    required this.coCCHN,
    required this.khongCCHN,
    required this.ready,
    required this.eligible,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.ratingAverage,
    this.ratingCount = 0,
    required this.skills,
  });

  UngVienDieuPhoi copyWith({
    bool? ready,
    double? ratingAverage,
    int? ratingCount,
  }) => UngVienDieuPhoi(
    uid: uid,
    name: name,
    unit: unit,
    restrictionReason: restrictionReason,
    coCCHN: coCCHN,
    khongCCHN: khongCCHN,
    ready: ready ?? this.ready,
    eligible: eligible,
    latitude: latitude,
    longitude: longitude,
    distance: distance,
    ratingAverage: ratingAverage ?? this.ratingAverage,
    ratingCount: ratingCount ?? this.ratingCount,
    skills: skills,
  );
}

DateTime? hanLoiMoi(Map<String, dynamic> data) {
  DateTime? date(Object? value) => value is Timestamp
      ? value.toDate()
      : value is String
      ? DateTime.tryParse(value)
      : null;
  final sent = date(data['thoiGianGui']);
  final explicit = date(data['hanPhanHoi']);
  final maximum = sent?.add(const Duration(minutes: 3));
  if (maximum == null) return explicit;
  return maximum;
}

List<UngVienDieuPhoi> top3CuuHoTheoDanhGia(
  Iterable<UngVienDieuPhoi> candidates,
) {
  final rows = candidates
      .where(
        (candidate) =>
            candidate.ready &&
            candidate.ratingAverage != null &&
            candidate.ratingCount > 0,
      )
      .toList();
  rows.sort((a, b) {
    final score = b.ratingAverage!.compareTo(a.ratingAverage!);
    if (score != 0) return score;
    final count = b.ratingCount.compareTo(a.ratingCount);
    if (count != 0) return count;
    return a.distance.compareTo(b.distance);
  });
  return rows.take(3).toList();
}
