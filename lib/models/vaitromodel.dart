class VaiTroModel {
  final String? maVaiTro;
  final String vaiTro;

  VaiTroModel({this.maVaiTro, required this.vaiTro});

  // Chuyển đối tượng Model thành Map để đẩy lên Firestore
  Map<String, dynamic> toMap() {
    return {'maVaiTro': maVaiTro, 'vaiTro': vaiTro};
  }

  // Tùy chọn: Chuyển dữ liệu từ Firestore về lại Model khi đọc dữ liệu
  factory VaiTroModel.fromMap(Map<String, dynamic> map, String id) {
    return VaiTroModel(maVaiTro: id, vaiTro: map['vaiTro'] ?? '');
  }
}
