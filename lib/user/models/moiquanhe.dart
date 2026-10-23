import 'package:cuhokhancap/user/models/basemodel.dart';

class MoiQuanHeModel implements BaseModel {
  final String? maMoiQuanHe;
  final String quanHe;

  MoiQuanHeModel({this.maMoiQuanHe, required this.quanHe});
  @override
  String? get id => maMoiQuanHe;
  // Chuyển đối tượng Model thành Map để đẩy lên Firestore
  @override
  Map<String, dynamic> toMap() {
    return {'maMoiQuanHe': maMoiQuanHe, 'quanHe': quanHe};
  }

  // Tùy chọn: Chuyển dữ liệu từ Firestore về lại Model khi đọc dữ liệu
  factory MoiQuanHeModel.fromMap(Map<String, dynamic> map, String id) {
    return MoiQuanHeModel(maMoiQuanHe: id, quanHe: map['quanHe'] ?? '');
  }
}
