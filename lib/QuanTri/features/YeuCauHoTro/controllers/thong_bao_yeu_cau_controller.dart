import 'dart:async';

import '../../../core/controller_an_toan.dart';
import '../../../core/xu_ly_loi.dart';
import '../services/thong_bao_yeu_cau_service.dart';

enum BoLocThongBao { tatCa, chuaDoc, daDoc }

class ThongBaoYeuCauController extends ControllerAnToan {
  final NguonThongBaoYeuCau service;

  ThongBaoYeuCauController(this.service);

  final Set<String> markingIds = {};
  final Map<String, ThongBaoAdmin> _recentCreated = {};
  final Map<String, ThongBaoAdmin> _recentSent = {};
  final Map<String, ThongBaoAdmin> _history = {};
  final List<ThongBaoAdmin> _allRows = [];
  List<ThongBaoAdmin> rows = [];
  StreamSubscription<TrangThongBao>? _createdSub;
  StreamSubscription<TrangThongBao>? _sentSub;
  StreamSubscription<List<ThongBaoAdmin>>? _legacySub;
  Timer? _countTimer;
  Object? _createdCursor;
  Object? _sentCursor;
  bool _createdHasMore = false;
  bool _sentHasMore = false;
  // Once a history request starts, only that source's history page may move
  // its cursor/hasMore; live page updates must never reset its boundary.
  bool _createdPagingStarted = false;
  bool _sentPagingStarted = false;
  final Set<String> _confirmedReadIds = {};
  int _countGeneration = 0;
  bool _createdReady = false;
  bool _sentReady = false;
  bool _usingLegacy = false;
  bool _loadingHistory = false;
  bool loading = true;
  bool hasMore = false;
  bool markingAll = false;
  String? error;
  int unreadTotal = 0;
  int totalCount = 0;
  int _displayLimit = 20;
  BoLocThongBao filter = BoLocThongBao.tatCa;

  int get readCount => (totalCount - unreadTotal).clamp(0, totalCount);
  bool get hasAnyRows => _allRows.isNotEmpty;

  List<ThongBaoAdmin> get _filtered => switch (filter) {
    BoLocThongBao.chuaDoc => _allRows.where((item) => !item.isRead).toList(),
    BoLocThongBao.daDoc => _allRows.where((item) => item.isRead).toList(),
    BoLocThongBao.tatCa => _allRows,
  };

  void start() {
    _createdSub = service.watchLatest('ngayTao').listen((page) {
      // Keep already-observed rows when a new notification pushes them
      // outside the live top-20 window after history paging has started.
      if (_createdPagingStarted) {
        final newIds = page.items.map((item) => item.id).toSet();
        for (final previous in _recentCreated.values) {
          if (!newIds.contains(previous.id)) {
            _history.putIfAbsent(
              previous.id,
              () => _applyConfirmedRead(previous),
            );
          }
        }
      }
      _recentCreated
        ..clear()
        ..addEntries(page.items.map((item) => MapEntry(item.id, item)));
      if (!_createdPagingStarted) {
        _createdCursor = page.cursor;
        _createdHasMore = page.hasMore;
      }
      _createdReady = true;
      _rebuild();
    }, onError: _fallbackToLegacy);
    _sentSub = service.watchLatest('ngayGui').listen((page) {
      if (_sentPagingStarted) {
        final newIds = page.items.map((item) => item.id).toSet();
        for (final previous in _recentSent.values) {
          if (!newIds.contains(previous.id)) {
            _history.putIfAbsent(
              previous.id,
              () => _applyConfirmedRead(previous),
            );
          }
        }
      }
      _recentSent
        ..clear()
        ..addEntries(page.items.map((item) => MapEntry(item.id, item)));
      if (!_sentPagingStarted) {
        _sentCursor = page.cursor;
        _sentHasMore = page.hasMore;
      }
      _sentReady = true;
      _rebuild();
    }, onError: _fallbackToLegacy);
  }

  void _fallbackToLegacy(Object failure) {
    if (disposed || _usingLegacy) return;
    _usingLegacy = true;
    _createdSub?.cancel();
    _sentSub?.cancel();
    _legacySub = service.watchLegacy().listen(
      (items) {
        _replaceAll(items.map(_applyConfirmedRead).toList());
        _createdHasMore = false;
        _sentHasMore = false;
        loading = false;
        error = null;
        _countLater();
        emit();
      },
      onError: (Object e) {
        if (disposed) return;
        loading = false;
        error = friendlyError(e);
        emit();
      },
    );
  }

  void _sort(List<ThongBaoAdmin> rows) {
    rows.sort((a, b) {
      final aTime = a.instant;
      final bTime = b.instant;
      if (aTime == null && bTime != null) return 1;
      if (aTime != null && bTime == null) return -1;
      final compared = aTime == null ? 0 : bTime!.compareTo(aTime);
      return compared != 0 ? compared : b.id.compareTo(a.id);
    });
  }

  void _updateVisible() {
    final filtered = _filtered;
    rows = filtered.take(_displayLimit).toList();
    hasMore =
        _createdHasMore || _sentHasMore || filtered.length > _displayLimit;
  }

  void _replaceAll(List<ThongBaoAdmin> next) {
    _sort(next);
    _allRows
      ..clear()
      ..addAll(next);
    _updateVisible();
  }

  ThongBaoAdmin _applyConfirmedRead(ThongBaoAdmin item) {
    if (!_confirmedReadIds.contains(item.id) || item.isRead) return item;
    return ThongBaoAdmin(item.id, {...item.data, 'daDoc': true}, item.instant);
  }

  void _updateKnownRead(Iterable<String> ids) {
    final readIds = ids.toSet();
    if (readIds.isEmpty) return;
    _confirmedReadIds.addAll(readIds);
    for (final source in [_recentCreated, _recentSent, _history]) {
      for (final id in readIds) {
        final item = source[id];
        if (item != null) source[id] = _applyConfirmedRead(item);
      }
    }
    if (_usingLegacy) {
      _replaceAll(_allRows.map(_applyConfirmedRead).toList());
      emit();
    } else {
      _rebuild();
    }
  }

  void _rebuild() {
    if (disposed || _usingLegacy || !_createdReady || !_sentReady) return;
    final merged = <String, ThongBaoAdmin>{
      ..._history,
      ..._recentSent,
      ..._recentCreated,
    };
    _replaceAll(merged.values.map(_applyConfirmedRead).toList());
    if (!_loadingHistory) loading = false;
    error = null;
    emit();
    _countLater();
  }

  void _countLater() {
    final generation = ++_countGeneration;
    _countTimer?.cancel();
    _countTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final counts = await service.count();
        if (disposed || generation != _countGeneration) return;
        totalCount = counts.total;
        unreadTotal = counts.unread;
      } catch (_) {
        if (disposed || generation != _countGeneration) return;
        // Fallback is limited to loaded rows if Firestore aggregation fails.
        totalCount = _allRows.length;
        unreadTotal = _allRows.where((item) => !item.isRead).length;
      }
      emit();
    });
  }

  void changeFilter(BoLocThongBao next) {
    filter = next;
    _updateVisible();
    emit();
  }

  Future<void> markRead(ThongBaoAdmin item) async {
    if (item.isRead || !markingIds.add(item.id)) return;
    emit();
    try {
      await service.markRead(item.id);
      if (disposed) return;
      // Update every local copy, including already-loaded historical pages.
      _updateKnownRead([item.id]);
      if (!item.isRead) {
        unreadTotal = (unreadTotal - 1).clamp(0, totalCount).toInt();
      }
      _countLater();
    } catch (e) {
      error = friendlyError(e);
      rethrow;
    } finally {
      markingIds.remove(item.id);
      emit();
    }
  }

  Future<int> markAllRead() async {
    if (markingAll ||
        (unreadTotal == 0 && _allRows.every((item) => item.isRead))) {
      return 0;
    }
    markingAll = true;
    emit();
    try {
      final count = await service.markAllRead();
      if (!disposed) {
        _updateKnownRead(_allRows.map((item) => item.id));
        unreadTotal = 0;
        _countLater();
      }
      return count;
    } finally {
      markingAll = false;
      emit();
    }
  }

  Future<void> loadMore() async {
    if (loading || _loadingHistory || !hasMore || disposed) return;
    if (_filtered.length > _displayLimit || _usingLegacy) {
      _displayLimit += 20;
      _updateVisible();
      emit();
      return;
    }
    loading = true;
    _loadingHistory = true;
    emit();
    try {
      // Freeze each requested source and cursor BEFORE awaiting Firebase.
      // Neither source order nor the live listener's mutable flags may be used
      // to associate a returned page with a cursor after the await.
      final requested = <({String field, Object cursor})>[
        if (_createdHasMore && _createdCursor != null)
          (field: 'ngayTao', cursor: _createdCursor!),
        if (_sentHasMore && _sentCursor != null)
          (field: 'ngayGui', cursor: _sentCursor!),
      ];
      for (final request in requested) {
        if (request.field == 'ngayTao') {
          _createdPagingStarted = true;
        } else {
          _sentPagingStarted = true;
        }
      }
      final pages = await Future.wait([
        for (final request in requested)
          service.fetchNext(request.field, request.cursor),
      ]);
      if (disposed || _usingLegacy) return;
      for (var index = 0; index < requested.length; index++) {
        final field = requested[index].field;
        final page = pages[index];
        for (final item in page.items) {
          _history[item.id] = _applyConfirmedRead(item);
        }
        if (field == 'ngayTao') {
          _createdCursor = page.cursor;
          _createdHasMore = page.hasMore;
        } else {
          _sentCursor = page.cursor;
          _sentHasMore = page.hasMore;
        }
      }
      _displayLimit += 20;
      final merged = <String, ThongBaoAdmin>{
        ..._history,
        ..._recentSent,
        ..._recentCreated,
      };
      _replaceAll(merged.values.map(_applyConfirmedRead).toList());
      error = null;
    } catch (e) {
      error = friendlyError(e);
    } finally {
      _loadingHistory = false;
      if (!disposed) {
        loading = false;
        emit();
      }
    }
  }

  Future<void> refresh() async {
    if (disposed) return;
    try {
      if (_usingLegacy) {
        _replaceAll(
          (await service.fetchLegacy()).map(_applyConfirmedRead).toList(),
        );
      } else {
        final pages = await Future.wait([
          service.fetchRecent('ngayTao'),
          service.fetchRecent('ngayGui'),
        ]);
        if (disposed) return;
        _recentCreated
          ..clear()
          ..addEntries(pages[0].items.map((item) => MapEntry(item.id, item)));
        _recentSent
          ..clear()
          ..addEntries(pages[1].items.map((item) => MapEntry(item.id, item)));
        if (!_createdPagingStarted) {
          _createdCursor = pages[0].cursor;
          _createdHasMore = pages[0].hasMore;
        }
        if (!_sentPagingStarted) {
          _sentCursor = pages[1].cursor;
          _sentHasMore = pages[1].hasMore;
        }
        _createdReady = true;
        _sentReady = true;
        _rebuild();
      }
      error = null;
    } catch (e) {
      if (!disposed) error = friendlyError(e);
    }
    if (!disposed) emit();
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    _countGeneration++;
    _createdSub?.cancel();
    _sentSub?.cancel();
    _legacySub?.cancel();
    super.dispose();
  }
}
