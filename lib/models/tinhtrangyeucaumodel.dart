import 'package:cuhokhancap/models/basemodel.dart';

class TinhTrangYeuCauModel implements BaseModel {
  final String maTinhTrangYeuCau;
  final String tinhTrang;

  TinhTrangYeuCauModel({
    required this.maTinhTrangYeuCau,
    required this.tinhTrang,
  });
  @override
  String? get id => maTinhTrangYeuCau;
  @override
  Map<String, dynamic> toMap() {
    return {'maTinhTrangYeuCau': maTinhTrangYeuCau, 'tinhTrang': tinhTrang};
  }

  factory TinhTrangYeuCauModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return TinhTrangYeuCauModel(
      maTinhTrangYeuCau: map['maTinhTrangYeuCau'] ?? id ?? '',
      tinhTrang: map['tinhTrang'] ?? '',
    );
  }
}
