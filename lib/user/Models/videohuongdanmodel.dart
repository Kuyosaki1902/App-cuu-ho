// lib/user/Models/videohuongdanmodel.dart
import 'package:flutter/material.dart';

/// Bỏ dấu tiếng Việt + chữ thường, dùng cho tìm kiếm ("cam mau" khớp "Cầm máu").
String boDauTiengViet(String input) {
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  var s = input.toLowerCase();
  groups.forEach((plain, accented) {
    for (final ch in accented.split('')) {
      s = s.replaceAll(ch, plain);
    }
  });
  return s;
}

class VideoHuongDanModel {
  final String maVideo;
  final String tieuDe;
  final String danhMuc;
  final String nhanKhanCap;
  final String mauNhanHex;
  final String thoiLuong;
  final String youtubeId;
  final String tieuDeBuoc;
  final List<String> cacBuocThucHien;
  final int thuTuUuTien;

  /// false = ẩn video (video YouTube bị xóa / chặn nhúng) mà không cần xóa doc.
  final bool kichHoat;

  VideoHuongDanModel({
    required this.maVideo,
    required this.tieuDe,
    required this.danhMuc,
    required this.nhanKhanCap,
    required this.mauNhanHex,
    required this.thoiLuong,
    required this.youtubeId,
    required this.tieuDeBuoc,
    required this.cacBuocThucHien,
    required this.thuTuUuTien,
    this.kichHoat = true,
  });

  /// Chuỗi đã bỏ dấu, gộp mọi trường tìm kiếm (tính 1 lần).
  late final String searchText = boDauTiengViet(
    '$tieuDe $danhMuc $nhanKhanCap ${cacBuocThucHien.join(' ')}',
  );

  bool get hopLe => kichHoat && youtubeId.trim().isNotEmpty;

  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';

  Color get badgeColor {
    try {
      var hex = mauNhanHex.replaceAll('#', '').trim();
      if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFC81E1E);
    }
  }

  factory VideoHuongDanModel.fromMap(Map<String, dynamic> map, String docId) {
    // Parse an toàn: không crash nếu dữ liệu thiếu hoặc sai kiểu
    final rawSteps = map['cacBuocThucHien'];
    final steps = rawSteps is List
        ? rawSteps.map((e) => e.toString()).toList()
        : <String>[];

    final rawOrder = map['thuTuUuTien'];
    final order = rawOrder is num
        ? rawOrder.toInt()
        : int.tryParse(rawOrder?.toString() ?? '') ?? 99;

    return VideoHuongDanModel(
      maVideo: (map['maVideo'] ?? docId).toString(),
      tieuDe: (map['tieuDe'] ?? '').toString(),
      danhMuc: (map['danhMuc'] ?? 'Khác').toString().trim(),
      nhanKhanCap: (map['nhanKhanCap'] ?? 'HƯỚNG DẪN').toString(),
      mauNhanHex: (map['mauNhanHex'] ?? '#C81E1E').toString(),
      thoiLuong: (map['thoiLuong'] ?? '00:00').toString(),
      youtubeId: (map['youtubeId'] ?? '').toString().trim(),
      tieuDeBuoc: (map['tieuDeBuoc'] ?? 'CÁC BƯỚC HÀNH ĐỘNG CỐT LÕI:')
          .toString(),
      cacBuocThucHien: steps,
      thuTuUuTien: order,
      kichHoat: map['kichHoat'] is bool ? map['kichHoat'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() => {
    'maVideo': maVideo,
    'tieuDe': tieuDe,
    'danhMuc': danhMuc,
    'nhanKhanCap': nhanKhanCap,
    'mauNhanHex': mauNhanHex,
    'thoiLuong': thoiLuong,
    'youtubeId': youtubeId,
    'tieuDeBuoc': tieuDeBuoc,
    'cacBuocThucHien': cacBuocThucHien,
    'thuTuUuTien': thuTuUuTien,
    'kichHoat': kichHoat,
  };
}

/// Kết quả FirebaseService.getVideoHuongDan(): kèm thông tin để controller
/// phân biệt "chưa có video" với "không có mạng".
class KetQuaVideoHuongDan {
  final List<VideoHuongDanModel> videos;

  /// Số document đọc được (kể cả document không hợp lệ)
  final int soDoc;

  /// true = dữ liệu lấy từ bộ nhớ đệm (không kết nối được máy chủ)
  final bool tuBoNhoDem;

  const KetQuaVideoHuongDan({
    required this.videos,
    required this.soDoc,
    required this.tuBoNhoDem,
  });
}
