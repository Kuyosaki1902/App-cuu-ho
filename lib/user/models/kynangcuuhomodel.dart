// lib/user/models/kynangcuuhomodel.dart

class KyNangCuuHoModel {
  final String maKiNangCuuHo;
  final String ten;
  final String moTa;

  KyNangCuuHoModel({
    required this.maKiNangCuuHo,
    required this.ten,
    required this.moTa,
  });

  factory KyNangCuuHoModel.fromMap(Map<String, dynamic> map, String docId) {
    return KyNangCuuHoModel(
      maKiNangCuuHo:
          (map['maKiNangCuuHo'] != null &&
              map['maKiNangCuuHo'].toString().isNotEmpty)
          ? map['maKiNangCuuHo'].toString()
          : docId,
      ten: map['ten'] ?? '',
      moTa: map['moTa'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'maKiNangCuuHo': maKiNangCuuHo, 'ten': ten, 'moTa': moTa};
  }
}
