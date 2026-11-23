import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/xu_ly_loi.dart';
import '../../../core/controller_an_toan.dart';
import '../models/tai_khoan_model.dart';
import '../../../models/ban_ghi.dart';
import '../../YeuCauHoTro/models/chi_tiet_yeu_cau_model.dart';
import '../../YeuCauHoTro/models/yeu_cau_ho_tro_model.dart';
import '../services/tai_khoan_service.dart';

class TaiKhoanController extends ControllerAnToan {
  final NguonTaiKhoan repository;
  TaiKhoanController(this.repository);
  List<TaiKhoan> items = [];
  Map<String, String> roles = {};
  bool loading = false;
  String? error;
  String query = '', filter = 'all', role = '';
  List<TaiKhoan> get filtered => items
      .where(
        (a) =>
            a.isManageableAccount &&
            a.matches(query) &&
            (role.isEmpty || a.role == role) &&
            (filter == 'all' ||
                filter == 'support' && a.canSupport ||
                filter == 'locked' && a.locked ||
                filter == 'verified' && a.approved ||
                filter == 'suspended' && a.suspended),
      )
      .toList();
  List<TaiKhoan> get visible => filtered;
  void search(String value) {
    query = value;
    emit();
  }

  void setFilter(String value) {
    filter = value;
    emit();
  }

  void setRole(String value) {
    role = value;
    emit();
  }

  int _gioiHan = 20;
  Object? cursor;
  bool hasMore = true;
  Future<void> more() => fetch(reset: false);
  Future<void> load() => fetch(reset: true);
  Future<void> fetch({required bool reset}) async {
    final live = repository;
    if (live is TaiKhoanTrucTiep) {
      if (disposed || loading || (!reset && !hasMore && error == null)) return;
      if (!reset && error == null) _gioiHan += 20;
      loading = true;
      error = null;
      emit();
      if (!luong.contains('roles')) {
        luong.listen(
          'roles',
          (live as TaiKhoanTrucTiep).watchRoles(),
          (value) {
            roles = value;
            emit();
          },
          (e) {
            error = friendlyError(e);
            emit();
          },
        );
      }
      luong.listen(
        'page',
        (live as TaiKhoanTrucTiep).watchPage(_gioiHan),
        (page) {
          items = page.items;
          hasMore = page.hasMore;
          loading = false;
          error = null;
          emit();
        },
        (e) {
          loading = false;
          error = friendlyError(e);
          emit();
        },
      );
      return;
    }

    if (disposed || loading || (!reset && !hasMore)) return;
    loading = true;
    error = null;
    emit();
    try {
      final source = repository;
      if (source is TaiKhoanPhanTrang) {
        final page = await (source as TaiKhoanPhanTrang).page(
          after: reset ? null : cursor,
        );
        if (disposed) return;
        items = reset ? page.items : [...items, ...page.items];
        cursor = page.cursor;
        hasMore = page.hasMore;
      } else {
        final next = await source.allAccounts();
        if (disposed) return;
        items = next;
        hasMore = false;
      }
    } catch (e) {
      error = friendlyError(e);
    } finally {
      loading = false;
      emit();
    }
  }
}

class BanGhiController extends ControllerAnToan {
  final NguonTaiKhoan repository;
  final String uid, kind;
  BanGhiController(this.repository, this.uid, this.kind);
  int _gioiHan = 20;
  List<BanGhi> items = [];
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  bool loading = false, hasMore = true, loaded = false;
  String? error;
  Future<void> load({bool reset = false}) async {
    final live = repository;
    if (live is TaiKhoanTrucTiep) {
      if (disposed || loading) return;
      if (!reset && loaded && !hasMore && error == null) return;
      if (reset && luong.contains('records') && error == null) return;
      if (!reset && loaded && error == null) _gioiHan += 20;
      loading = true;
      error = null;
      emit();
      luong.listen(
        'records',
        (live as TaiKhoanTrucTiep).watchRecords(uid, kind, _gioiHan),
        (page) {
          items = page.items;
          hasMore = page.hasMore;
          loaded = true;
          loading = false;
          error = null;
          emit();
        },
        (e) {
          loading = false;
          error = friendlyError(e);
          emit();
        },
      );
      return;
    }

    if (disposed || loading) return;
    loading = true;
    error = null;
    emit();
    try {
      final page = await repository.records(
        uid,
        kind,
        after: reset ? null : cursor,
      );
      if (disposed) return;
      items = reset ? page.items : [...items, ...page.items];
      cursor = page.cursor;
      hasMore = page.hasMore;
      loaded = true;
    } catch (e) {
      error = friendlyError(e);
    } finally {
      loading = false;
      emit();
    }
  }
}

class ChiTietTaiKhoanController extends ControllerAnToan {
  final NguonTaiKhoan repository;
  final String uid;
  ChiTietTaiKhoanController(this.repository, this.uid);
  TaiKhoan? account;
  bool loading = false, busy = false;
  String? error;
  Future<void> load() async {
    final live = repository;
    if (live is TaiKhoanTrucTiep) {
      if (disposed || (luong.contains('detail') && error == null)) return;
      loading = true;
      error = null;
      emit();
      luong.listen(
        'detail',
        (live as TaiKhoanTrucTiep).watchAccount(uid),
        (value) {
          account = value;
          loading = false;
          error = null;
          emit();
        },
        (e) {
          account = null;
          loading = false;
          error = friendlyError(e);
          emit();
        },
      );
      return;
    }

    if (disposed || loading) return;
    loading = true;
    error = null;
    emit();
    try {
      final next = await repository.get(uid);
      if (!disposed) account = next;
    } catch (e) {
      account = null;
      error = friendlyError(e);
    } finally {
      loading = false;
      emit();
    }
  }

  Future<String?> perform(String action, String reason) async {
    if (disposed || busy || loading || account == null || error != null) {
      return 'Tài khoản chưa sẵn sàng.';
    }
    if (reason.trim().length < 5 || reason.trim().length > 500) {
      return 'Lý do phải có từ 5 đến 500 ký tự.';
    }
    if (!['khoa', 'mo_khoa', 'tam_ngung', 'khoi_phuc'].contains(action)) {
      return 'Thao tác không hợp lệ.';
    }
    busy = true;
    emit();
    String? failure;
    try {
      await repository.action(account!, action, reason.trim());
    } catch (e) {
      failure = friendlyError(e);
    } finally {
      if (!disposed) await load();
      busy = false;
      emit();
    }
    if (failure == null && error != null) {
      return 'Thao tác đã được lưu nhưng chưa tải lại được dữ liệu. Vui lòng tải lại trước khi tiếp tục.';
    }
    return failure;
  }
}

class CaHienTaiController extends ControllerAnToan {
  final NguonTaiKhoan repository;
  final String uid;
  CaHienTaiController(this.repository, this.uid);
  List<BanGhi> items = [];
  bool loading = false;
  String? error;
  Future<void> load() async {
    final live = repository;
    if (live is TaiKhoanTrucTiep) {
      if (disposed || (luong.contains('cases') && error == null)) return;
      loading = true;
      error = null;
      emit();
      luong.listen(
        'cases',
        (live as TaiKhoanTrucTiep).watchCurrentCases(uid),
        (value) {
          items = value;
          loading = false;
          error = null;
          emit();
        },
        (e) {
          items = [];
          loading = false;
          error = friendlyError(e);
          emit();
        },
      );
      return;
    }

    if (disposed || loading) return;
    loading = true;
    error = null;
    emit();
    try {
      final ids = <String>{};
      DocumentSnapshot<Map<String, dynamic>>? after;
      while (!disposed) {
        final page = await repository.records(uid, 'helped', after: after);
        for (final r in page.items) {
          if (assignmentStatus(r.data['maTrangThaiTiepNhan']) == 'duoc_chon') {
            ids.add(r.text('maYeuCau', ''));
          }
        }
        if (!page.hasMore) break;
        after = page.cursor;
      }
      final next = <BanGhi>[];
      for (final id in ids) {
        if (disposed) return;
        final r = await repository.sos(id);
        if (r == null) {
          throw StateError('Có phân công trỏ tới SOS không tồn tại: $id');
        }
        if (![
          'hoan_thanh',
          'da_huy',
        ].contains(normalizeRequestStatus(r.data['maTinhTrangYeuCau']))) {
          next.add(r);
        }
      }
      items = next;
    } catch (e) {
      error = friendlyError(e);
    } finally {
      loading = false;
      emit();
    }
  }
}
