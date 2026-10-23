import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuhokhancap/user/models/basemodel.dart';

class ChiTietMoTaHienTruongModel implements BaseModel {
  final String maYeuCau; // 🌟 Dùng maYeuCau làm khóa chính luôn
  final String? videoUrl;
  final String? ghiAmUrl;
  final dynamic ghiChuText; // Hỗ trợ Map 2 chiều hoặc String
  final DateTime thoiGianTao;

  ChiTietMoTaHienTruongModel({
    required this.maYeuCau,
    this.videoUrl,
    this.ghiAmUrl,
    this.ghiChuText,
    required this.thoiGianTao,
  });

  @override
  String? get id => maYeuCau;

  @override
  Map<String, dynamic> toMap() {
    return {
      'maYeuCau': maYeuCau,
      'videoUrl': videoUrl,
      'ghiAmUrl': ghiAmUrl,
      'ghiChuText': ghiChuText,
      'thoiGianTao': thoiGianTao,
    };
  }

  factory ChiTietMoTaHienTruongModel.fromMap(
    Map<String, dynamic> map, [
    String? id,
  ]) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ChiTietMoTaHienTruongModel(
      maYeuCau: map['maYeuCau'] ?? id ?? '',
      videoUrl: map['videoUrl'],
      ghiAmUrl: map['ghiAmUrl'],
      ghiChuText: map['ghiChuText'],
      thoiGianTao: parseDateTime(map['thoiGianTao']),
    );
  }
}
