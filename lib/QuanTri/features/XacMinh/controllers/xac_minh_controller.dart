import '../../../core/xu_ly_loi.dart';
import '../models/xac_minh_model.dart';
import '../services/xac_minh_service.dart';
import '../../../core/controller_an_toan.dart';

class XacMinhController extends ControllerAnToan {
  final NguonXacMinh repository;
  XacMinhController(this.repository);
  List<HoSoXacMinh> items = [];
  String query = '', status = 'cho_duyet', type = '';
  bool newest = true, loading = false;
  String? error;
  List<HoSoXacMinh> get filtered {
    final result = items
        .where(
          (p) =>
              (status.isEmpty || p.status == status) &&
              (type.isEmpty || p.collection == type) &&
              p.matches(query),
        )
        .toList();
    result.sort((a, b) {
      if (a.submitted == null) return b.submitted == null ? 0 : 1;
      if (b.submitted == null) return -1;
      return newest
          ? b.submitted!.compareTo(a.submitted!)
          : a.submitted!.compareTo(b.submitted!);
    });
    return result;
  }

  void filter({String? q, String? s, String? t, bool? n}) {
    query = q ?? query;
    status = s ?? status;
    type = t ?? type;
    newest = n ?? newest;
    emit();
  }

  int _gioiHan = 10;
  Object? cursor;
  bool hasMore = true;
  Future<void> more() => fetch(reset: false);
  Future<void> load() => fetch(reset: true);
  Future<void> fetch({required bool reset}) async {
    final live = repository;
    if (live is XacMinhTrucTiep) {
      if (disposed || loading || (!reset && !hasMore && error == null)) return;
      if (reset && luong.contains('page') && error == null) return;
      if (!reset && error == null) _gioiHan += 10;
      loading = true;
      error = null;
      emit();

      luong.listen(
        'page',
        (live as XacMinhTrucTiep).watchPage(_gioiHan),
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
      if (source is XacMinhPhanTrang) {
        final page = await (source as XacMinhPhanTrang).page(
          after: reset ? null : cursor,
        );
        if (disposed) return;
        items = reset ? page.items : [...items, ...page.items];
        cursor = page.cursor;
        hasMore = page.hasMore;
      } else {
        final data = await source.list();
        if (disposed) return;
        items = data;
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

class ChiTietXacMinhController extends ControllerAnToan {
  final NguonXacMinh repository;
  final String collection, uid;
  ChiTietXacMinhController(this.repository, this.collection, this.uid);
  ChiTietXacMinh? detail;
  bool loading = false, busy = false;
  String? error;
  Future<void> load() async {
    final live = repository;
    if (live is XacMinhTrucTiep) {
      if (disposed || (luong.contains('detail') && error == null)) return;
      loading = true;
      error = null;
      emit();
      luong.listen(
        'detail',
        (live as XacMinhTrucTiep).watchDetail(collection, uid),
        (value) {
          detail = value;
          loading = false;
          error = null;
          emit();
        },
        (e) {
          detail = null;
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
      final next = await repository.detail(collection, uid);
      if (!disposed) detail = next;
    } catch (e) {
      error = friendlyError(e);
      detail = null;
    } finally {
      loading = false;
      emit();
    }
  }

  Future<String?> submit(String action) async {
    if (disposed || busy || loading || detail == null || error != null) {
      return 'Hồ sơ chưa sẵn sàng.';
    }
    if (!['approve', 'reject', 'supplement'].contains(action)) {
      return 'Thao tác không hợp lệ.';
    }
    if (!detail!.profile.accountExists) {
      return 'Không tìm thấy tài khoản NguoiDung/$uid. Chưa thể xử lý hồ sơ.';
    }
    if (!detail!.profile.actionable) {
      return 'Hồ sơ đã kết thúc xét duyệt. Vui lòng tải lại.';
    }
    busy = true;
    emit();
    String? failure;
    try {
      await repository.review(detail!.profile, action);
    } catch (e) {
      failure = friendlyError(e);
    } finally {
      if (!disposed) await load();
      busy = false;
      emit();
    }
    if (failure == null && error != null) {
      return 'Trạng thái đã được lưu nhưng chưa tải lại được hồ sơ. Vui lòng tải lại trước khi tiếp tục.';
    }
    return failure;
  }
}
