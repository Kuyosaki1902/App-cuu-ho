import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/kiem_tra_quyen_ghi.dart';
import '../../models/ban_ghi.dart';

class KyNangDanhMuc {
  final String id;
  final String ten;
  final String moTa;

  const KyNangDanhMuc({
    required this.id,
    required this.ten,
    required this.moTa,
  });

  factory KyNangDanhMuc.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return KyNangDanhMuc(
      id: doc.id,
      ten: '${data['tenKyNang'] ?? ''}',
      moTa: '${data['moTa'] ?? ''}',
    );
  }
}

class KyNangDaKhaiBao {
  final String id;
  final String ten;
  final bool tuKhai;

  const KyNangDaKhaiBao({
    required this.id,
    required this.ten,
    required this.tuKhai,
  });
}

class KyNangAdminService {
  final FirebaseFirestore db;
  KyNangAdminService({FirebaseFirestore? db})
    : db = db ?? FirebaseFirestore.instance;

  static final RegExp _maKyNangPattern = RegExp(
    r'^kn_[a-z0-9]+(?:_[a-z0-9]+)*$',
  );

  Stream<List<KyNangDanhMuc>> watchDanhMuc() =>
      db.collection('KyNangCuuHo').snapshots().map((snapshot) {
        final items = snapshot.docs.map(KyNangDanhMuc.fromDoc).toList();
        items.sort(
          (a, b) => a.ten.toLowerCase().compareTo(b.ten.toLowerCase()),
        );
        return items;
      });

  // Tab Quản lý kỹ năng chỉ dành cho cứu hộ viên không có CCHN.
  // Lọc ngay từ Firebase, tránh tải hồ sơ và kỹ năng của nhóm có CCHN.
  Stream<List<BanGhi>> watchNguoiCuuHoKhongCCHN() => db
      .collection('NguoiDung')
      .where(
        'maVaiTro',
        whereIn: const [
          'vaitro_cuuhochuacocc',
          'vaitro_cuhokhongcocc', // Giữ tương thích với mã vai trò cũ.
        ],
      )
      .snapshots()
      .map((snapshot) {
        final items = snapshot.docs.map(BanGhi.fromDoc).toList();
        items.sort(
          (a, b) => a
              .text('hoTen')
              .toLowerCase()
              .compareTo(b.text('hoTen').toLowerCase()),
        );
        return items;
      });

  Future<List<KyNangDaKhaiBao>> kyNangCuaNguoiDung(
    String uid,
    Map<String, String> tenDanhMuc,
  ) async {
    final pages = await Future.wait([
      db.collection('ChiTietKyNang').where('maNguoiDung', isEqualTo: uid).get(),
      db
          .collection('ChiTietKyNang')
          .doc(uid)
          .collection('DanhSachKyNang')
          .get(),
      db
          .collection('ChiTietKyNangCuuHo')
          .where('maNguoiDung', isEqualTo: uid)
          .get(),
    ]);

    final found = <String, KyNangDaKhaiBao>{};
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final page = pages[pageIndex];
      for (final doc in page.docs) {
        final data = doc.data();
        final rawId = data['maKyNangCuuHo'] ?? data['maKyNang'];
        final id = rawId is String && rawId.trim().isNotEmpty
            ? rawId.trim()
            : (pageIndex > 0 ? doc.id : '');
        final customName = '${data['tenKyNangTudo'] ?? ''}'.trim();
        if (id.isEmpty && customName.isEmpty) continue;
        final key = id.isNotEmpty ? id : 'custom_${doc.id}';
        final catalogName = tenDanhMuc[id];
        final name = customName.isNotEmpty ? customName : (catalogName ?? id);
        found[key] = KyNangDaKhaiBao(
          id: id.isNotEmpty ? id : key,
          ten: name,
          tuKhai: customName.isNotEmpty || catalogName == null,
        );
      }
    }

    final result = found.values.toList();
    result.sort((a, b) => a.ten.toLowerCase().compareTo(b.ten.toLowerCase()));
    return result;
  }

  Future<String> taoKyNang({
    required String id,
    required String ten,
    required String moTa,
  }) async {
    final cleanId = id.trim();
    if (!_maKyNangPattern.hasMatch(cleanId) || cleanId.length > 80) {
      throw StateError(
        'Mã kỹ năng không hợp lệ. Dùng dạng kn_ten_ky_nang, chỉ gồm chữ thường, số và dấu gạch dưới.',
      );
    }
    await _luuKyNang(id: cleanId, ten: ten, moTa: moTa, taoMoi: true);
    return cleanId;
  }

  Future<void> capNhatKyNang({
    required String id,
    required String ten,
    required String moTa,
  }) => _luuKyNang(id: id, ten: ten, moTa: moTa, taoMoi: false);

  Future<void> _luuKyNang({
    required String id,
    required String ten,
    required String moTa,
    required bool taoMoi,
  }) async {
    final cleanId = id.trim();
    final cleanName = ten.trim();
    final cleanDescription = moTa.trim();
    if (!_maKyNangPattern.hasMatch(cleanId) ||
        cleanId.length > 80 ||
        cleanName.length < 2 ||
        cleanName.length > 100 ||
        cleanDescription.length > 500) {
      throw StateError('Mã, tên hoặc mô tả kỹ năng không hợp lệ.');
    }

    final actor = currentAdminUid();
    final adminRef = db.collection('Admin').doc(actor);
    final skillRef = db.collection('KyNangCuuHo').doc(cleanId);
    await db.runTransaction((tx) async {
      final admin = await tx.get(adminRef);
      final current = await tx.get(skillRef);
      if (admin.data()?['trangThai'] != 'hoat_dong') {
        throw StateError('Tài khoản Admin không còn quyền thao tác.');
      }
      if (taoMoi && current.exists) {
        throw StateError('Mã kỹ năng đã tồn tại. Hãy chọn mã khác.');
      }
      if (!taoMoi && !current.exists) {
        throw StateError('Kỹ năng không còn tồn tại. Hãy tải lại danh sách.');
      }
      tx.set(skillRef, {
        'maKyNang': cleanId,
        'tenKyNang': cleanName,
        'moTa': cleanDescription,
      }, SetOptions(merge: true));
    });
  }

  Future<void> xoaKyNang(String id) async {
    final rootSkillLink = await db.collection('ChiTietKyNang').doc(id).get();
    final legacySkillLink = await db
        .collection('ChiTietKyNangCuuHo')
        .doc(id)
        .get();
    final legacyCatalogLinks = await Future.wait([
      db
          .collection('KyNangCuuHo')
          .doc('kynangcoban')
          .collection('DanhSachKyNang')
          .doc(id)
          .get(),
      db
          .collection('KyNangCuuHo')
          .doc('kynangtuhoc')
          .collection('DanhSachKyNang')
          .doc(id)
          .get(),
    ]);
    final usage = await Future.wait([
      db
          .collection('ChiTietKyNang')
          .where('maKyNang', isEqualTo: id)
          .limit(1)
          .get(),
      db
          .collection('ChiTietKyNang')
          .where('maKyNangCuuHo', isEqualTo: id)
          .limit(1)
          .get(),
      db
          .collectionGroup('DanhSachKyNang')
          .where('maKyNangCuuHo', isEqualTo: id)
          .limit(1)
          .get(),
      db
          .collectionGroup('DanhSachKyNang')
          .where('maKyNang', isEqualTo: id)
          .limit(1)
          .get(),
      db
          .collection('ChiTietKyNangCuuHo')
          .where('maKyNangCuuHo', isEqualTo: id)
          .limit(1)
          .get(),
      db
          .collection('ChiTietKyNangCuuHo')
          .where('maKyNang', isEqualTo: id)
          .limit(1)
          .get(),
    ]);
    if (rootSkillLink.exists ||
        legacySkillLink.exists ||
        legacyCatalogLinks.any((doc) => doc.exists) ||
        usage.any((page) => page.docs.isNotEmpty)) {
      throw StateError(
        'Kỹ năng đang được người cứu hộ sử dụng nên không thể xóa.',
      );
    }

    final actor = currentAdminUid();
    final adminRef = db.collection('Admin').doc(actor);
    final skillRef = db.collection('KyNangCuuHo').doc(id);
    await db.runTransaction((tx) async {
      final admin = await tx.get(adminRef);
      final current = await tx.get(skillRef);
      final currentAssignment = await tx.get(
        db.collection('ChiTietKyNang').doc(id),
      );
      final legacyAssignment = await tx.get(
        db.collection('ChiTietKyNangCuuHo').doc(id),
      );
      final legacyCatalogDocs = await Future.wait([
        tx.get(
          db
              .collection('KyNangCuuHo')
              .doc('kynangcoban')
              .collection('DanhSachKyNang')
              .doc(id),
        ),
        tx.get(
          db
              .collection('KyNangCuuHo')
              .doc('kynangtuhoc')
              .collection('DanhSachKyNang')
              .doc(id),
        ),
      ]);
      if (admin.data()?['trangThai'] != 'hoat_dong') {
        throw StateError('Tài khoản Admin không còn quyền thao tác.');
      }
      if (currentAssignment.exists ||
          legacyAssignment.exists ||
          legacyCatalogDocs.any((doc) => doc.exists)) {
        throw StateError(
          'Kỹ năng đang được sử dụng hoặc còn liên kết trong danh mục cũ. Không thể xóa lúc này.',
        );
      }
      if (!current.exists) return;
      tx.delete(skillRef);
    });
  }
}
