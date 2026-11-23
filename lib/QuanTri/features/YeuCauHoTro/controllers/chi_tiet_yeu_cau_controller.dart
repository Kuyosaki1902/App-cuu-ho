import 'dart:async';

import '../../../core/xu_ly_loi.dart';
import '../../../models/ban_ghi.dart';
import '../models/yeu_cau_ho_tro_model.dart';
import '../services/chi_tiet_yeu_cau_service.dart';
import '../../../core/controller_an_toan.dart';

class ChiTietYeuCauController extends ControllerAnToan {
  final NguonChiTietYeuCau repository;
  final String id;
  ChiTietYeuCauController(this.repository, this.id);
  BanGhi? request, nanNhan;
  List<BanGhi> assignments = [];
  final people = <String, BanGhi?>{};
  final profiles = <String, Map<String, dynamic>>{};
  String typeName = '', _typeId = '';
  String? typeError;
  final profileErrors = <String, String>{};
  final personErrors = <String, String>{};
  bool loading = true, assignmentsLoading = true, busy = false;
  String? error, assignmentError, loiNanNhan;
  StreamSubscription<dynamic>? _requestSub, _assignmentSub, _nanNhanSub;
  final _peopleSubs = <String, StreamSubscription<BanGhi?>>{};
  final _peopleTokens = <String, Object>{};
  String? _maNanNhan;
  int generation = 0;
  bool _starting = false;

  Future<void> start() async {
    if (_starting || busy || disposed) return;
    _starting = true;
    final token = ++generation;
    luong.cancel('type');
    for (final uid in _peopleTokens.keys) {
      luong.cancel('profile-$uid');
    }
    loading = true;
    assignmentsLoading = true;
    error = null;
    assignmentError = null;
    loiNanNhan = null;
    nanNhan = null;
    _maNanNhan = null;
    request = null;
    assignments = [];
    people.clear();
    profiles.clear();
    typeName = '';
    typeError = null;
    profileErrors.clear();
    _typeId = '';
    personErrors.clear();
    emit();
    await _requestSub?.cancel();
    await _assignmentSub?.cancel();
    await _nanNhanSub?.cancel();
    for (final sub in _peopleSubs.values) {
      await sub.cancel();
    }
    _peopleSubs.clear();
    _peopleTokens.clear();
    if (disposed || token != generation) {
      _starting = false;
      return;
    }
    _requestSub = repository
        .watchRequest(id)
        .listen(
          (r) {
            if (disposed || token != generation) return;
            request = r;
            loading = false;
            error = null;
            final rawType = r?.data['maLoaiYeuCau'];
            final typeId = rawType is String ? rawType : '';
            if (typeId != _typeId) {
              _typeId = typeId;
              typeName = '';
              typeError = null;
              luong.cancel('type');
              if (typeId.isNotEmpty && !typeId.contains('/')) {
                final source = repository;
                final stream = source is ChiTietYeuCauTrucTiep
                    ? (source as ChiTietYeuCauTrucTiep).watchRequestType(typeId)
                    : Stream.fromFuture(source.requestType(typeId));
                luong.listen(
                  'type',
                  stream,
                  (name) {
                    if (disposed || token != generation || _typeId != typeId) {
                      return;
                    }
                    typeName = name;
                    typeError = null;
                    emit();
                  },
                  (e) {
                    if (disposed || token != generation || _typeId != typeId) {
                      return;
                    }
                    typeName = '';
                    typeError = friendlyError(e);
                    emit();
                  },
                );
              }
            }
            final uid = r == null ? '' : maNanNhan(r.data);
            if (uid != _maNanNhan) {
              _nanNhanSub?.cancel();
              nanNhan = null;
              loiNanNhan = null;
              _maNanNhan = uid;
              if (uid.isNotEmpty && !uid.contains('/')) {
                _nanNhanSub = repository
                    .watchPerson(uid)
                    .listen(
                      (p) {
                        if (disposed ||
                            token != generation ||
                            _maNanNhan != uid) {
                          return;
                        }
                        nanNhan = p;
                        loiNanNhan = null;
                        emit();
                      },
                      onError: (Object e) {
                        if (disposed ||
                            token != generation ||
                            _maNanNhan != uid) {
                          return;
                        }
                        nanNhan = null;
                        loiNanNhan = friendlyError(e);
                        emit();
                      },
                    );
              }
            }
            emit();
          },
          onError: (Object e) {
            if (disposed || token != generation) return;
            request = null;
            loading = false;
            error = friendlyError(e);
            emit();
          },
        );
    _assignmentSub = repository
        .watchSelected(id)
        .listen(
          (rows) {
            if (disposed || token != generation) return;
            assignments = rows;
            assignmentsLoading = false;
            assignmentError = null;
            final ids = rows
                .map((r) => r.data['maNguoiCuuHo'])
                .whereType<String>()
                .where((s) => s.isNotEmpty && !s.contains('/'))
                .toSet();
            for (final uid in _peopleSubs.keys.toList()) {
              if (!ids.contains(uid)) {
                _peopleSubs.remove(uid)?.cancel();
                people.remove(uid);
                profiles.remove(uid);
                personErrors.remove(uid);
                profileErrors.remove(uid);
                _peopleTokens.remove(uid);
                luong.cancel('profile-$uid');
              }
            }
            for (final uid in ids) {
              if (_peopleSubs.containsKey(uid)) continue;
              final personToken = Object();
              _peopleTokens[uid] = personToken;
              final source = repository;
              final stream = source is ChiTietYeuCauTrucTiep
                  ? (source as ChiTietYeuCauTrucTiep).watchHelperProfile(uid)
                  : Stream.fromFuture(source.helperProfile(uid));
              luong.listen(
                'profile-$uid',
                stream,
                (profile) {
                  if (disposed ||
                      token != generation ||
                      _peopleTokens[uid] != personToken) {
                    return;
                  }
                  profiles[uid] = profile;
                  profileErrors.remove(uid);
                  emit();
                },
                (e) {
                  if (disposed ||
                      token != generation ||
                      _peopleTokens[uid] != personToken) {
                    return;
                  }
                  profiles.remove(uid);
                  profileErrors[uid] = friendlyError(e);
                  emit();
                },
              );
              _peopleSubs.putIfAbsent(
                uid,
                () => repository
                    .watchPerson(uid)
                    .listen(
                      (p) {
                        if (disposed ||
                            token != generation ||
                            _peopleTokens[uid] != personToken) {
                          return;
                        }
                        people[uid] = p;
                        personErrors.remove(uid);
                        emit();
                      },
                      onError: (Object e) {
                        if (disposed ||
                            token != generation ||
                            _peopleTokens[uid] != personToken) {
                          return;
                        }
                        people.remove(uid);
                        personErrors[uid] = friendlyError(e);
                        emit();
                      },
                    ),
              );
            }
            emit();
          },
          onError: (Object e) {
            if (disposed || token != generation) return;
            assignments = [];
            people.clear();
            profiles.clear();
            profileErrors.clear();
            personErrors.clear();
            for (final sub in _peopleSubs.values) {
              sub.cancel();
            }
            _peopleSubs.clear();
            for (final uid in _peopleTokens.keys) {
              luong.cancel('profile-$uid');
            }
            _peopleTokens.clear();
            assignmentsLoading = false;
            assignmentError = friendlyError(e);
            emit();
          },
        );
    _starting = false;
  }

  Future<String?> save(BanGhi assignment, String outcome, String note) async {
    if (disposed ||
        assignmentsLoading ||
        !assignments.any((a) => a.id == assignment.id) ||
        busy ||
        loading ||
        request == null ||
        error != null ||
        assignmentError != null) {
      return 'Ca chưa sẵn sàng.';
    }
    busy = true;
    emit();
    try {
      await repository.saveCheck(request!, assignment, outcome, note);
      return null;
    } catch (e) {
      return friendlyError(e);
    } finally {
      busy = false;
      emit();
    }
  }

  @override
  void dispose() {
    generation++;
    _requestSub?.cancel();
    _assignmentSub?.cancel();
    _nanNhanSub?.cancel();
    for (final sub in _peopleSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
