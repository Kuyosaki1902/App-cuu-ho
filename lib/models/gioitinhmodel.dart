class GioiTinhModel {
  final String? maGioiTinh;
  final String gioiTinh;

  GioiTinhModel({this.maGioiTinh, required this.gioiTinh});

  // Chuyển đối tượng Model thành Map để đẩy lên Firestore
  Map<String, dynamic> toMap() {
    return {'maGioiTinh': maGioiTinh, 'gioiTinh': gioiTinh};
  }

  // Tùy chọn: Chuyển dữ liệu từ Firestore về lại Model khi đọc dữ liệu
  factory GioiTinhModel.fromMap(Map<String, dynamic> map, String id) {
    return GioiTinhModel(maGioiTinh: id, gioiTinh: map['gioiTinh'] ?? '');
  }
}
