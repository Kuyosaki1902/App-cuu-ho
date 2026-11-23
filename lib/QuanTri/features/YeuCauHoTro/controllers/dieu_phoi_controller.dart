import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/controller_an_toan.dart';
import '../../../models/ban_ghi.dart';
import '../models/dieu_phoi_model.dart';
import '../models/yeu_cau_ho_tro_model.dart';
import '../models/chi_tiet_yeu_cau_model.dart';
import '../services/dieu_phoi_service.dart';

class DieuPhoiController extends ControllerAnToan {
  final DieuPhoiService service;
  final String id;
  DieuPhoiController(this.service, this.id);
  BanGhi? request, invitation;
  List<UngVienDieuPhoi> candidates = [];
  List<BanGhi> caseInvitations = [];
  Map<String, String> skills = {};
  StreamSubscription<dynamic>? _usersSub, _assignmentsSub, _caseInvitationsSub;
  final _eligibilitySubs = <StreamSubscription<dynamic>>[];
  int _limit = 0, _generation = 0;
  final _users = <String, UngVienDieuPhoi>{};
  bool loading = false,
      busy = false,
      hasMore = true,
      readyOnly = false,
      additional = false;
  double radius = 1;
  String type = 'all', skill = '', query = '';
  String? error, _invitationId, ratingError;
  bool ratingsLoading = false;
  int _ratingGeneration = 0;
  StreamSubscription<dynamic>? _requestSub, _invitationSub;
  Timer? _clock;
  bool get mine => request?.data['maAdminDieuPhoi'] == service.actor;
  bool get active => coTheDieuPhoi(request?.data['maTinhTrangYeuCau']);
  bool get pending => caseInvitations.any(
    (row) => pendingAssignmentCodes.contains(row.data['maTrangThaiTiepNhan']),
  );
  int? get seconds {
    final date = hanLoiMoi(invitation?.data ?? const <String, dynamic>{});
    return date?.difference(DateTime.now()).inSeconds.clamp(0, 180).toInt();
  }

  List<UngVienDieuPhoi> get topRated => top3CuuHoTheoDanhGia(candidates);

  List<UngVienDieuPhoi> get visible =>
      candidates
          .where(
            (c) =>
                c.distance <= radius &&
                (!readyOnly || c.ready) &&
                (type == 'all' ||
                    type == 'pro' && c.coCCHN ||
                    type == 'volunteer' && c.khongCCHN) &&
                (skill.isEmpty || c.skills.contains(skill)) &&
                requestSearchText(
                  '${c.name} ${c.uid}',
                ).contains(requestSearchText(query)),
          )
          .toList()
        ..sort((a, b) => a.distance.compareTo(b.distance));
  void start() {
    for (final collection in ['HoSoCuuHoCoCCHN', 'HoSoCuuHoKhongCCHN']) {
      _eligibilitySubs.add(
        service.watchProfiles(collection).listen((_) => _refreshCandidates()),
      );
    }
    _eligibilitySubs.add(
      service.watchRestrictions().listen((_) => _refreshCandidates()),
    );
    _caseInvitationsSub = service
        .watchCaseInvitations(id)
        .listen(
          (page) {
            if (disposed) return;
            caseInvitations = page.docs.map(BanGhi.fromDoc).toList();
            for (final row in page.docs) {
              service.trackInvitation(row);
            }
            emit();
          },
          onError: (Object e) {
            if (!disposed) {
              assignmentError = describeError('lời mời', e);
              emit();
            }
          },
        );
    _requestSub = service
        .watch(id)
        .listen(
          (r) {
            if (disposed) return;
            final previous = request?.data;
            request = r;
            if (previous == null ||
                r == null ||
                previous['viDo'] != r.data['viDo'] ||
                previous['kinhDo'] != r.data['kinhDo'] ||
                previous['maNguoiYeuCau'] != r.data['maNguoiYeuCau']) {
              _watchUsers(_limit == 0 ? 100 : _limit, reset: true);
            }
            final next = r?.data['maLoiMoiDieuPhoi'] as String?;
            if (_invitationId != next) {
              _invitationId = next;
              invitation = null;
              _invitationSub?.cancel();
              if (next != null && next.isNotEmpty) {
                _invitationSub = service
                    .invitation(next)
                    .listen(
                      (i) {
                        if (disposed || _invitationId != next) return;
                        invitation = i;
                        emit();
                      },
                      onError: (Object e) {
                        if (!disposed) {
                          error =
                              'Không tải được lời mời. Hãy mở lại màn hình.';
                          emit();
                        }
                      },
                    );
              }
            }
            emit();
          },
          onError: (Object e) {
            if (!disposed) {
              error = 'Không tải được yêu cầu. Hãy mở lại màn hình.';
              emit();
            }
          },
        );
    service
        .skills()
        .then((s) {
          if (!disposed) {
            skills = s;
            emit();
          }
        })
        .catchError((Object e) {
          if (!disposed) {
            error = 'Không tải được danh mục kỹ năng.';
            emit();
          }
        });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (disposed) return;
      service.expireDue().catchError((Object e) {
        if (!disposed) {
          assignmentError =
              'Chưa cập nhật được lời mời hết hạn. Kiểm tra kết nối và thử lại.';
          emit();
        }
      });
      if (_day != service.dispatchDay) retryAssignments();
      emit();
    });
  }

  String? _day;
  Map<String, String>? _busyIds;
  String reason(UngVienDieuPhoi user) => user.restrictionReason.isNotEmpty
      ? user.restrictionReason
      : _busyIds?[user.uid] ??
            (assignmentError != null
                ? 'Chưa xác định được trạng thái'
                : 'Đang kiểm tra phân công');
  Set<String> _watched = {};
  String? assignmentError;
  Timer? _assignmentRetry;

  String describeError(String source, Object e) {
    if (kDebugMode) debugPrint('[DieuPhoi/$source] $e');
    final code = e is FirebaseException ? e.code : 'unknown';
    return switch (code) {
      'permission-denied' => 'Không có quyền đọc dữ liệu $source.',
      'failed-precondition' => 'Truy vấn $source chưa sẵn sàng ($code).',
      'unavailable' => 'Tạm mất kết nối khi đọc $source.',
      _ => 'Không cập nhật được $source ($code).',
    };
  }

  void retryAssignments() {
    if (disposed) return;
    _assignmentRetry?.cancel();
    _assignmentsSub?.cancel();
    _day = service.dispatchDay;
    _watched = _users.keys.toSet();
    _busyIds = null;
    for (final entry in _users.entries.toList()) {
      _users[entry.key] = entry.value.copyWith(ready: false);
    }
    candidates = _users.values.toList();
    _assignmentsSub = service
        .watchBusy(_watched.toList(), _day!)
        .listen(
          (busyIds) {
            if (disposed) return;
            assignmentError = null;
            _busyIds = busyIds;
            for (final entry in _users.entries.toList()) {
              final person = entry.value;
              _users[entry.key] = person.copyWith(
                ready: person.eligible && !busyIds.containsKey(person.uid),
              );
            }
            candidates = _users.values.toList();
            emit();
          },
          onError: (Object e) {
            if (!disposed) {
              _busyIds = null;
              for (final entry in _users.entries.toList()) {
                _users[entry.key] = entry.value.copyWith(ready: false);
              }
              candidates = _users.values.toList();
              assignmentError = describeError('phân công', e);
              if (e is FirebaseException && e.code == 'unavailable') {
                _assignmentRetry = Timer(
                  const Duration(seconds: 5),
                  retryAssignments,
                );
              }
              emit();
            }
          },
        );
  }

  void searchRadius(double km) {
    if (!const [1.0, 3.0, 5.0].contains(km)) return;
    radius = km;
    error = null;
    ratingError = null;
    _watchUsers(100, reset: true);
    emit();
  }

  Future<void> loadMore() async {
    if (!loading && hasMore && !disposed) _watchUsers(_limit + 100);
  }

  void _refreshCandidates() {
    if (disposed || _limit == 0 || request == null || loading) return;
    _watchUsers(_limit, reset: true);
  }

  void _watchUsers(int limit, {bool reset = false}) {
    final generation = ++_generation;
    _usersSub?.cancel();
    if (reset) {
      _ratingGeneration++;
      ratingsLoading = false;
      ratingError = null;
      _users.clear();
      candidates = [];
    }
    final incident = YeuCauHoTro(id, request?.data ?? {});
    _limit = limit;
    loading = incident.hasLocation;
    if (!loading) return;
    final km = radius;
    _usersSub = service
        .users(limit, incident.latitude!, km)
        .asyncMap((page) async {
          final ids = page.docs.map((doc) => doc.id).toSet();
          final changed = page.docChanges
              .where((change) => change.type != DocumentChangeType.removed)
              .map((change) => change.doc.id)
              .toSet();
          final updates = page.docs
              .where((d) => changed.contains(d.id))
              .toList();
          final next = Map<String, UngVienDieuPhoi>.of(_users)
            ..removeWhere((key, _) => !ids.contains(key));
          for (var i = 0; i < updates.length; i += 5) {
            if (disposed || generation != _generation) return;
            await Future.wait(
              updates.skip(i).take(5).map((doc) async {
                final user = await service.candidate(doc, incident, km);
                if (user == null) {
                  next.remove(doc.id);
                } else {
                  next[doc.id] = user;
                }
              }),
            );
          }
          if (disposed || generation != _generation) return;
          final busyIds = _busyIds;
          _users
            ..clear()
            ..addAll(
              next.map(
                (uid, user) => MapEntry(
                  uid,
                  user.copyWith(
                    ready:
                        user.eligible &&
                        busyIds != null &&
                        !busyIds.containsKey(uid),
                  ),
                ),
              ),
            );
          candidates = next.values.toList();
          hasMore = page.size == limit;
          loading = hasMore;
          emit();
          if (hasMore && !disposed && generation == _generation) {
            _watchUsers(limit + 100);
            return;
          }
          if (!setEquals(_watched, _users.keys.toSet()) ||
              _day != service.dispatchDay) {
            retryAssignments();
          }
          _loadRatings();
        })
        .listen(
          (_) {},
          onError: (Object e) {
            if (disposed || generation != _generation) return;
            loading = false;
            error = describeError('ứng viên', e);
            emit();
          },
        );
  }

  Future<void> _loadRatings() async {
    final token = ++_ratingGeneration;
    final ids = _users.keys.toList();
    ratingsLoading = true;
    ratingError = null;
    emit();
    try {
      final values = await service.ratings(ids);
      if (disposed || token != _ratingGeneration) return;
      _users.updateAll((uid, user) {
        final rating = values[uid];
        return UngVienDieuPhoi(
          uid: user.uid,
          name: user.name,
          unit: user.unit,
          restrictionReason: user.restrictionReason,
          coCCHN: user.coCCHN,
          khongCCHN: user.khongCCHN,
          ready: user.ready,
          eligible: user.eligible,
          latitude: user.latitude,
          longitude: user.longitude,
          distance: user.distance,
          ratingAverage: rating?.trungBinh,
          ratingCount: rating?.soLuot ?? 0,
          skills: user.skills,
        );
      });
      candidates = _users.values.toList();
      ratingsLoading = false;
      emit();
    } catch (e) {
      if (disposed || token != _ratingGeneration) return;
      ratingsLoading = false;
      ratingError = describeError('đánh giá', e);
      emit();
    }
  }

  Future<int?> inviteTop3() async {
    if (busy ||
        disposed ||
        !mine ||
        !active ||
        pending ||
        loading ||
        ratingsLoading ||
        ratingError != null) {
      return null;
    }
    final selected = topRated;
    if (selected.isEmpty) {
      error =
          'Không có cứu hộ viên đủ điều kiện và có đánh giá thực tế trong bán kính này.';
      emit();
      return null;
    }
    busy = true;
    error = null;
    emit();
    try {
      return await service.sendTop3Invitations(
        id,
        uids: selected.map((row) => row.uid).toList(),
        radius: radius,
        additional: additional,
      );
    } catch (e) {
      error = e is FirebaseFunctionsException
          ? (e.message ?? 'Không gửi được lời mời đồng thời.')
          : e is StateError
          ? e.message.toString()
          : 'Không gửi được lời mời đồng thời. Hãy tải lại danh sách.';
      return null;
    } finally {
      busy = false;
      emit();
    }
  }

  Future<void> perform(
    String action, {
    String? uid,
    String? expectedInvitation,
    String? expectedInvitationPath,
  }) async {
    if (busy || disposed) return;
    busy = true;
    error = null;
    emit();
    try {
      await service.act(
        id,
        action,
        uid: uid,
        invitationId: expectedInvitation ?? invitation?.id,
        invitationPath: expectedInvitationPath ?? invitation?.path,
        radius: radius,
        additional: additional,
      );
    } catch (e) {
      if (!disposed) {
        error = e is StateError
            ? e.message.toString()
            : 'Không thực hiện được. Kiểm tra kết nối và quyền truy cập.';
      }
    } finally {
      busy = false;
      emit();
    }
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _assignmentsSub?.cancel();
    for (final subscription in _eligibilitySubs) {
      subscription.cancel();
    }
    _assignmentRetry?.cancel();
    _clock?.cancel();
    _requestSub?.cancel();
    _invitationSub?.cancel();
    _caseInvitationsSub?.cancel();
    super.dispose();
  }
}
