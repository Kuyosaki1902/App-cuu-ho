import 'dart:async';

import '../../../core/xu_ly_loi.dart';
import '../models/yeu_cau_ho_tro_model.dart';
import '../services/yeu_cau_ho_tro_service.dart';
import '../../../core/controller_an_toan.dart';

class YeuCauHoTroController extends ControllerAnToan {
  final NguonYeuCauHoTro repository;
  YeuCauHoTroController(this.repository);

  List<YeuCauHoTro> items = [];
  String query = '', tab = 'active', status = '';
  String urgencyFilter = '';
  String typeFilter = '';
  String ownerFilter = 'all';
  String timeFilter = 'all';
  String sortMode = 'priority';
  String interventionFilter = '';
  String adminId = '';
  bool loading = false, hasMore = true;
  String? error;
  int _gioiHan = 20;
  Object? cursor;
  bool lastReset = true;
  List<YeuCauHoTro> _firstPage = [];
  List<YeuCauHoTro> _olderPages = [];
  List<YeuCauHoTro> _urgentCases = [];
  final List<StreamSubscription<List<YeuCauHoTro>>> _olderSubscriptions = [];
  // Single authoritative row store: never hold enriched copies in widgets.
  final Map<String, YeuCauHoTro> _hydratedByCase = {};
  final Map<String, String> _pendingHydrations = {};
  final Map<String, String> _runningHydrations = {};
  int _runningHydrationCount = 0;
  int _loadedLimit = 20;
  String? _liveWindowTab;
  final Map<String, int> _tabWindowLimits = {'active': 20, 'closed': 20};

  bool _firstHasMore = true;
  int _tabGeneration = 0;
  int _urgentGeneration = 0;

  bool get interventionOnly => interventionFilter.isNotEmpty;

  int get activeFilterCount =>
      (status.isNotEmpty ? 1 : 0) +
      (urgencyFilter.isNotEmpty ? 1 : 0) +
      (typeFilter.isNotEmpty ? 1 : 0) +
      (ownerFilter != 'all' ? 1 : 0) +
      (timeFilter != 'all' ? 1 : 0) +
      (interventionFilter.isNotEmpty ? 1 : 0);

  List<String> get availableUrgencies =>
      items
          .map((item) => item.urgencyKey)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) {
          final left = int.tryParse(a);
          final right = int.tryParse(b);
          if (left != null && right != null) {
            return left.compareTo(right);
          }
          if (left != null) {
            return -1;
          }
          if (right != null) {
            return 1;
          }
          return a.compareTo(b);
        });

  Map<String, String> get availableTypes {
    final result = <String, String>{};
    for (final item in items) {
      final id = item.text('maLoaiYeuCau');
      if (id.isEmpty) continue;
      result[id] = item.typeName.isNotEmpty ? item.typeName : id;
    }
    return result;
  }

  List<YeuCauHoTro> get filtered {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = switch (timeFilter) {
      'today' => today,
      '7days' => now.subtract(const Duration(days: 7)),
      '30days' => now.subtract(const Duration(days: 30)),
      _ => null,
    };

    final result = items.where((r) {
      if (r.tab != tab) {
        return false;
      }
      if (status.isNotEmpty && r.status != status) {
        return false;
      }
      if (urgencyFilter.isNotEmpty && r.urgencyKey != urgencyFilter) {
        return false;
      }
      if (typeFilter.isNotEmpty && r.text('maLoaiYeuCau') != typeFilter) {
        return false;
      }
      if (interventionFilter == 'all' && !r.needsIntervention) {
        return false;
      }
      if (interventionFilter == 'dispatch' && !r.needsDispatch) {
        return false;
      }
      if (interventionFilter == 'check' && !r.needsCheck) {
        return false;
      }

      final owner = r.text('maAdminDieuPhoi');
      if (ownerFilter == 'mine' && (adminId.isEmpty || owner != adminId)) {
        return false;
      }
      if (ownerFilter == 'others' &&
          (owner.isEmpty || adminId.isEmpty || owner == adminId)) {
        return false;
      }
      if (ownerFilter == 'unassigned' && owner.isNotEmpty) {
        return false;
      }

      if (cutoff != null) {
        final created = r.createdAt;
        if (created == null || created.isBefore(cutoff)) {
          return false;
        }
      }
      return r.matches(query);
    }).toList();

    int priority(YeuCauHoTro r) {
      if (r.urgencyLevel == 1) {
        return 0;
      }
      if (r.needsDispatch) {
        return 1;
      }
      if (r.needsCheck) {
        return 2;
      }
      if (r.urgencyLevel == 2) {
        return 3;
      }
      if (r.status == 'dang_cuu_ho') {
        return 4;
      }
      if (r.status == 'da_phan_cong') {
        return 5;
      }
      if (r.status == 'cho_tiep_nhan') {
        return 6;
      }
      return 7;
    }

    int compareDate(YeuCauHoTro a, YeuCauHoTro b, {required bool newest}) {
      final left = a.createdAt;
      final right = b.createdAt;
      if (left == null && right == null) {
        return a.id.compareTo(b.id);
      }
      if (left == null) {
        return 1;
      }
      if (right == null) {
        return -1;
      }
      return newest ? right.compareTo(left) : left.compareTo(right);
    }

    result.sort((a, b) {
      if (sortMode == 'oldest') {
        return compareDate(a, b, newest: false);
      }
      if (sortMode == 'newest' || (tab == 'closed' && sortMode == 'priority')) {
        return compareDate(a, b, newest: true);
      }
      final byPriority = priority(a).compareTo(priority(b));
      return byPriority != 0 ? byPriority : compareDate(a, b, newest: false);
    });
    return result;
  }

  int count(String tab) => items.where((r) => r.tab == tab).length;
  int get interventions => items.where((r) => r.needsIntervention).length;

  Future<void> retry() {
    final live = repository;
    if (live is YeuCauCuaSoTrucTiep) {
      _watchLiveWindow(live as YeuCauCuaSoTrucTiep);
      return Future.value();
    }
    return fetch(reset: lastReset);
  }

  // Only person, type and assignee labels are enriched. The raw Firestore row
  // remains authoritative for status, owner, location and all dispatch fields.
  String _identity(YeuCauHoTro row) => [
    maNanNhan(row.data),
    row.text('maLoaiYeuCau'),
    row.status,
    row.text('maAdminDieuPhoi'),
    '${row.data['danhSachPhanCongVien']}',
  ].join('\u001f');

  void _scheduleHydration(List<YeuCauHoTro> rawRows) {
    if (repository is! YeuCauCuaSoTrucTiep && repository is! YeuCauTheoTab)
      return;
    final active = rawRows.map((row) => row.id).toSet();
    _hydratedByCase.removeWhere((id, _) => !active.contains(id));
    _pendingHydrations.removeWhere((id, _) => !active.contains(id));
    for (final raw in rawRows) {
      final existing = _hydratedByCase[raw.id];
      if (existing != null && _identity(existing) == _identity(raw)) continue;
      final signature = _identity(raw);
      if (_runningHydrations[raw.id] == signature) continue;
      _pendingHydrations[raw.id] = signature;
    }
    _drainHydrations();
  }

  void _drainHydrations() {
    if (disposed ||
        (repository is! YeuCauCuaSoTrucTiep && repository is! YeuCauTheoTab))
      return;
    final source = repository;
    while (_runningHydrationCount < 4 && _pendingHydrations.isNotEmpty) {
      final id = _pendingHydrations.keys.first;
      final signature = _pendingHydrations.remove(id)!;
      // Do not run two jobs for the same case simultaneously.
      if (_runningHydrations.containsKey(id)) continue;
      final raw = items.where((row) => row.id == id).firstOrNull;
      if (raw == null || _identity(raw) != signature) continue;
      _runningHydrations[id] = signature;
      _runningHydrationCount++;
      final future = source is YeuCauCuaSoTrucTiep
          ? (source as YeuCauCuaSoTrucTiep).hydrateRow(raw)
          : (source as YeuCauTheoTab).hydrateRow(raw);
      future
          .then((enriched) {
            if (disposed) return;
            final latest = items.where((row) => row.id == id).firstOrNull;
            if (latest == null ||
                _identity(latest) != signature ||
                _runningHydrations[id] != signature)
              return;
            _hydratedByCase[id] = enriched;
            // Reconstruct from the latest raw data to prevent stale status or
            // ownership from overwriting a newer Firestore snapshot.
            items = items
                .map(
                  (row) => row.id != id
                      ? row
                      : YeuCauHoTro(
                          row.id,
                          row.data,
                          createdAt: row.createdAt,
                          tenNanNhan: enriched.tenNanNhan,
                          typeName: enriched.typeName,
                          assigneeName: enriched.assigneeName,
                        ),
                )
                .toList();
            emit();
          })
          .catchError((Object _) {
            // The raw row stays visible. A later refresh can retry labels.
          })
          .whenComplete(() {
            if (_runningHydrations[id] == signature) {
              _runningHydrations.remove(id);
            }
            _runningHydrationCount--;
            if (disposed) return;
            final latest = items.where((row) => row.id == id).firstOrNull;
            if (latest != null && _identity(latest) != signature) {
              _pendingHydrations[id] = _identity(latest);
            }
            _drainHydrations();
          });
    }
  }

  void search(String value) {
    query = value;
    emit();
  }

  void selectTab(String value) {
    if (tab == value) return;
    tab = value;
    status = '';
    interventionFilter = '';
    if (repository is YeuCauCuaSoTrucTiep || repository is YeuCauTheoTab) {
      fetch(reset: true);
    } else {
      emit();
    }
  }

  void selectStatus(String value) {
    status = value;
    emit();
  }

  void toggleStatus(String value) {
    status = status == value ? '' : value;
    if (status.isNotEmpty) {
      interventionFilter = '';
    }
    emit();
  }

  void setInterventionFilter(String value) {
    interventionFilter = interventionFilter == value ? '' : value;
    if (interventionFilter.isNotEmpty) {
      status = '';
    }
    emit();
  }

  void toggleIntervention() {
    interventionFilter = interventionFilter == 'all' ? '' : 'all';
    emit();
  }

  void showInterventions() {
    final changedTab = tab != 'active';
    tab = 'active';
    status = '';
    query = '';
    interventionFilter = 'all';
    if (changedTab &&
        (repository is YeuCauCuaSoTrucTiep || repository is YeuCauTheoTab)) {
      fetch(reset: true);
    } else {
      emit();
    }
  }

  void applyFilters({
    required String status,
    required String urgency,
    required String type,
    required String owner,
    required String time,
    required String intervention,
    required String sort,
  }) {
    this.status = status;
    urgencyFilter = urgency;
    typeFilter = type;
    ownerFilter = owner;
    timeFilter = time;
    interventionFilter = intervention;
    sortMode = sort;
    emit();
  }

  void resetFilters() {
    status = '';
    urgencyFilter = '';
    typeFilter = '';
    ownerFilter = 'all';
    timeFilter = 'all';
    interventionFilter = '';
    sortMode = 'priority';
    emit();
  }

  void _mergePages() {
    final byId = <String, YeuCauHoTro>{};
    for (final item in _olderPages) {
      byId[item.id] = item;
    }
    for (final item in _firstPage) {
      byId[item.id] = item;
    }
    if (tab == 'active') {
      for (final item in _urgentCases) {
        byId[item.id] = item;
      }
    }
    final rawRows = byId.values.where((row) => row.tab == tab).toList();
    items = rawRows.map((raw) {
      final enriched = _hydratedByCase[raw.id];
      if (enriched == null || _identity(enriched) != _identity(raw)) return raw;
      return YeuCauHoTro(
        raw.id,
        raw.data,
        createdAt: raw.createdAt,
        tenNanNhan: enriched.tenNanNhan,
        typeName: enriched.typeName,
        assigneeName: enriched.assigneeName,
      );
    }).toList();
    emit();
    _scheduleHydration(rawRows);
  }

  void _watchLiveWindow(YeuCauCuaSoTrucTiep source, {bool reset = false}) {
    final token = ++_tabGeneration;
    if (reset) _loadedLimit = _tabWindowLimits[tab] ?? 20;
    final sameTab = _liveWindowTab == tab;
    _liveWindowTab = tab;
    for (final subscription in _olderSubscriptions) {
      subscription.cancel();
    }
    _olderSubscriptions.clear();
    _olderPages = [];
    if (!sameTab) {
      // A new tab must not show rows belonging to the previous tab.
      _pendingHydrations.clear();
      _firstPage = [];
      _urgentCases = [];
      _hydratedByCase.clear();
      items = [];
      _urgentGeneration++;
    }
    // Same tab: retain the 20 (or more) visible rows until the new live
    // window arrives. Urgent updates can safely merge into this snapshot.
    loading = true;
    error = null;
    // Preserve visible rows while the larger window listener starts.
    emit();
    final selectedTab = tab;
    luong.listen(
      'tab-page',
      source.watchTabWindow(selectedTab, _loadedLimit),
      (page) {
        if (disposed || token != _tabGeneration || tab != selectedTab) return;
        _firstPage = page.items;
        cursor = page.cursor;
        hasMore = page.hasMore;
        loading = false;
        error = null;
        _mergePages();
      },
      (failure) {
        if (disposed || token != _tabGeneration) return;
        loading = false;
        error = friendlyError(failure);
        emit();
      },
    );
    if (selectedTab == 'active') {
      // Keep the urgent stream alive as page size expands. Its callback does
      // not depend on the window token, only on the actual tab generation.
      if (!sameTab || !luong.contains('urgent')) {
        final urgentToken = ++_urgentGeneration;
        luong.listen(
          'urgent',
          source.watchUrgentActive(),
          (cases) {
            if (disposed || urgentToken != _urgentGeneration || tab != 'active')
              return;
            _urgentCases = cases;
            _mergePages();
          },
          (failure) {
            if (disposed || urgentToken != _urgentGeneration) return;
            error = friendlyError(failure);
            emit();
          },
        );
      }
    } else {
      luong.cancel('urgent');
    }
  }

  void _watchTab(YeuCauTheoTab source) {
    final token = ++_tabGeneration;
    for (final subscription in _olderSubscriptions) {
      subscription.cancel();
    }
    _olderSubscriptions.clear();
    _hydratedByCase.clear();
    _firstPage = [];
    _olderPages = [];
    _urgentCases = [];
    cursor = null;
    _firstHasMore = true;
    hasMore = true;
    loading = true;
    error = null;
    _mergePages();

    final selectedTab = tab;
    luong.listen(
      'tab-page',
      source.watchFirstTabPage(selectedTab),
      (page) {
        if (disposed || token != _tabGeneration || tab != selectedTab) return;
        // Do not discard loaded history when the first page changes. The
        // history watches below update those IDs independently.
        _firstPage = page.items;
        _firstHasMore = page.hasMore;
        if (_olderPages.isEmpty) {
          cursor = page.cursor;
          hasMore = _firstHasMore;
        }
        loading = false;
        error = null;
        _mergePages();
      },
      (failure) {
        if (disposed || token != _tabGeneration) return;
        loading = false;
        error = friendlyError(failure);
        emit();
      },
    );
    if (selectedTab == 'active') {
      luong.listen(
        'urgent',
        source.watchUrgentActive(),
        (cases) {
          if (disposed || token != _tabGeneration) return;
          _urgentCases = cases;
          _mergePages();
        },
        (failure) {
          if (disposed || token != _tabGeneration) return;
          error = friendlyError(failure);
          lastReset = true;
          emit();
        },
      );
    } else {
      luong.cancel('urgent');
      _urgentCases = [];
    }
  }

  Future<void> _loadOlder(YeuCauTheoTab source) async {
    if (disposed || loading || !hasMore || cursor == null) return;
    final token = _tabGeneration;
    final selectedTab = tab;
    loading = true;
    error = null;
    emit();
    try {
      final result = await source.fetchNextTabPage(selectedTab, cursor);
      if (disposed || token != _tabGeneration || selectedTab != tab) return;
      final byId = <String, YeuCauHoTro>{
        for (final item in _olderPages) item.id: item,
        for (final item in result.items) item.id: item,
      };
      _olderPages = byId.values.toList();
      final watchedIds = result.items.map((row) => row.id).toList();
      if (watchedIds.isNotEmpty) {
        final sub = source
            .watchLoadedRows(watchedIds)
            .listen(
              (latest) {
                if (disposed || token != _tabGeneration || tab != selectedTab) {
                  return;
                }
                final changedIds = watchedIds.toSet();
                final updated = <String, YeuCauHoTro>{
                  for (final row in _olderPages)
                    if (!changedIds.contains(row.id)) row.id: row,
                  for (final row in latest) row.id: row,
                };
                _olderPages = updated.values.toList();
                _mergePages();
              },
              onError: (Object failure) {
                if (!disposed && token == _tabGeneration) {
                  error = friendlyError(failure);
                  emit();
                }
              },
            );
        _olderSubscriptions.add(sub);
      }
      cursor = result.cursor;
      hasMore = result.hasMore;
      _mergePages();
    } catch (failure) {
      if (disposed || token != _tabGeneration) return;
      error = friendlyError(failure);
    } finally {
      if (!disposed && token == _tabGeneration) {
        loading = false;
        emit();
      }
    }
  }

  Future<void> load() => fetch(reset: true);
  Future<void> more() => fetch(reset: false);

  Future<void> fetch({required bool reset}) async {
    final live = repository;
    if (live is YeuCauCuaSoTrucTiep) {
      if (disposed) return;
      lastReset = reset;
      if (reset) {
        _watchLiveWindow(live as YeuCauCuaSoTrucTiep, reset: true);
      } else if (!loading && hasMore) {
        _loadedLimit += 20;
        _tabWindowLimits[tab] = _loadedLimit;
        _watchLiveWindow(live as YeuCauCuaSoTrucTiep);
      }
      return;
    }
    if (live is YeuCauTheoTab) {
      if (disposed) return;
      lastReset = reset;
      if (reset) {
        _watchTab(live as YeuCauTheoTab);
      } else {
        await _loadOlder(live as YeuCauTheoTab);
      }
      return;
    }
    if (live is YeuCauTrucTiep) {
      if (disposed || loading || (!reset && !hasMore && error == null)) return;
      if (reset && luong.contains('page') && error == null) return;
      lastReset = reset;
      if (!reset && error == null) _gioiHan += 20;
      loading = true;
      error = null;
      emit();

      luong.listen(
        'page',
        (live as YeuCauTrucTiep).watchPage(_gioiHan),
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
    lastReset = reset;
    emit();
    try {
      final page = await repository.page(after: reset ? null : cursor);
      if (disposed) return;
      final unique = <String, YeuCauHoTro>{
        if (!reset)
          for (final item in items) item.id: item,
        for (final item in page.items) item.id: item,
      };
      items = unique.values.toList();
      cursor = page.cursor;
      hasMore = page.hasMore;
    } catch (e) {
      error = friendlyError(e);
    } finally {
      loading = false;
      emit();
    }
  }

  @override
  void dispose() {
    for (final sub in _olderSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
