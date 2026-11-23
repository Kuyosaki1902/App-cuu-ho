import 'package:cloud_firestore/cloud_firestore.dart';

class BanGhi {
  final String id;
  final Map<String, dynamic> data;
  final String? path;
  const BanGhi(this.id, this.data, {this.path});
  factory BanGhi.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) => BanGhi(
    doc.reference.parent.id == 'DanhSachPhanCong'
        ? (doc.data()?['maPhanCong'] as String? ?? doc.reference.path)
        : doc.id,
    doc.data() ?? {},
    path: doc.reference.path,
  );
  String text(String key, [String fallback = 'Chưa có']) =>
      data[key]?.toString() ?? fallback;
}

class TrangBanGhi {
  final List<BanGhi> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
  const TrangBanGhi(this.items, this.cursor, this.hasMore);
}
