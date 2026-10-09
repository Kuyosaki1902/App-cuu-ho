import 'package:cuhokhancap/models/basemodel.dart';

class VaiTroModel implements BaseModel {
  final String? maVaiTro;
  final String vaiTro;

  VaiTroModel({this.maVaiTro, required this.vaiTro});
  @override
  String? get id => maVaiTro;
  // Chuyển đối tượng Model thành Map để đẩy lên Firestore
  @override
  Map<String, dynamic> toMap() {
    return {'maVaiTro': maVaiTro, 'vaiTro': vaiTro};
  }

  // Tùy chọn: Chuyển dữ liệu từ Firestore về lại Model khi đọc dữ liệu
  factory VaiTroModel.fromMap(Map<String, dynamic> map, String id) {
    return VaiTroModel(maVaiTro: id, vaiTro: map['vaiTro'] ?? '');
  }
}
