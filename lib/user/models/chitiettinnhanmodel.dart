// lib/user/models/chitiettinnhanmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChiTietTinNhanModel {
  final String maTinNhan;
  final String maPhongChat;
  final String maNguoiGui;
  final String noiDung;
  final String? fileDinhKemUrl;
  final String loaiTinNhan;
  final DateTime thoiGianGui;

  ChiTietTinNhanModel({
    required this.maTinNhan,
    required this.maPhongChat,
    required this.maNguoiGui,
    required this.noiDung,
    this.fileDinhKemUrl,
    required this.loaiTinNhan,
    required this.thoiGianGui,
  });

  factory ChiTietTinNhanModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChiTietTinNhanModel(
      maTinNhan: docId,
      maPhongChat: map['maPhongChat'] ?? '',
      maNguoiGui: map['maNguoiGui'] ?? '',
      noiDung: map['noiDung'] ?? '',
      fileDinhKemUrl: map['fileDinhKemUrl'],
      loaiTinNhan: map['loaiTinNhan'] ?? 'text',
      thoiGianGui:
          (map['thoiGianGui'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maPhongChat': maPhongChat,
      'maNguoiGui': maNguoiGui,
      'noiDung': noiDung,
      'fileDinhKemUrl': fileDinhKemUrl,
      'loaiTinNhan': loaiTinNhan,
      'thoiGianGui': FieldValue.serverTimestamp(),
    };
  }
}
